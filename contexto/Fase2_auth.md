# 🔐 Fase 2 — Autenticación JWT + Trazabilidad de Sesiones

Este documento contiene el código **exacto** ya aplicado en el servidor, para poder reconstruir el estado actual desde cero si hace falta. Última actualización: 12 de agosto de 2026, con `authentication.0001_initial` ya migrada.

## Estado actual
- ✅ Modelo `UserSession` creado y migrado
- ✅ `rest_framework_simplejwt.token_blacklist` instalado y migrado
- ✅ `SIMPLE_JWT` configurado en `settings.py`
- ✅ Endpoints: `login/`, `refresh/`, `logout/`, `me/`
- ✅ Middleware de trazabilidad (`SessionActivityMiddleware`)
- ⬜ Probar login + `/me/` con curl (paso inmediato siguiente)
- ⬜ Conectar el frontend (`modules/auth/`)

## Archivos de backend

### `backend/apps/authentication/models.py`
```python
from django.conf import settings
from django.db import models


class UserSession(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sessions')
    session_id = models.CharField(max_length=255, unique=True)  # jti del access token
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=512, null=True, blank=True)
    login_at = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now_add=True)
    logout_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-login_at']

    def __str__(self):
        return f"{self.user} — {self.login_at:%Y-%m-%d %H:%M}"
```

### `backend/apps/authentication/serializers.py`
```python
from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
```

### `backend/apps/authentication/views.py`
```python
from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import AccessToken, RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .models import UserSession
from .serializers import UserProfileSerializer


def get_client_ip(request):
    forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    if forwarded:
        return forwarded.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')


class LoginView(TokenObtainPairView):
    """Login estandar de Simple JWT, pero ademas registra la sesion para trazabilidad."""

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            access_token = AccessToken(response.data['access'])
            jti = access_token['jti']
            user_id = access_token['user_id']

            UserSession.objects.create(
                user_id=user_id,
                session_id=jti,
                ip_address=get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')[:512],
            )
        return response


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({'detail': 'El campo "refresh" es obligatorio.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            return Response({'detail': 'Token invalido o ya expirado.'}, status=status.HTTP_400_BAD_REQUEST)

        jti = request.auth.get('jti') if request.auth else None
        if jti:
            UserSession.objects.filter(session_id=jti, is_active=True).update(
                is_active=False,
                logout_at=timezone.now(),
            )

        return Response({'detail': 'Sesion cerrada correctamente.'}, status=status.HTTP_200_OK)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data)
```

### `backend/apps/authentication/urls.py`
```python
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import LoginView, LogoutView, MeView

urlpatterns = [
    path('login/', LoginView.as_view(), name='auth-login'),
    path('refresh/', TokenRefreshView.as_view(), name='auth-refresh'),
    path('logout/', LogoutView.as_view(), name='auth-logout'),
    path('me/', MeView.as_view(), name='auth-me'),
]
```

### `backend/common/middleware.py`
```python
from django.utils import timezone
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError


class SessionActivityMiddleware:
    """Actualiza last_activity de UserSession en cada request autenticado con JWT."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if auth_header.startswith('Bearer '):
            raw_token = auth_header.split(' ', 1)[1]
            try:
                token = AccessToken(raw_token)
                jti = token['jti']
                from apps.authentication.models import UserSession
                UserSession.objects.filter(session_id=jti, is_active=True).update(
                    last_activity=timezone.now()
                )
            except TokenError:
                pass

        return self.get_response(request)
```

### `backend/core/urls.py` (versión final tras la Fase 2)
```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', include('apps.health.urls')),
    path('api/auth/', include('apps.authentication.urls')),
]
```

### Cambios en `backend/core/settings.py`

`INSTALLED_APPS` debe contener, en este orden relativo:
```python
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'apps.health',
    'apps.authentication',
```

`MIDDLEWARE` debe incluir, después de `XFrameOptionsMiddleware`:
```python
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'common.middleware.SessionActivityMiddleware',
```

Al final del archivo:
```python
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=30),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

## Endpoints disponibles (backend, puerto 8001 en el host)

| Método | Ruta | Body | Descripción |
|---|---|---|---|
| POST | `/api/auth/login/` | `{"username", "password"}` | Devuelve `access` + `refresh`, registra `UserSession` |
| POST | `/api/auth/refresh/` | `{"refresh"}` | Devuelve nuevo `access` (y `refresh` rotado) |
| POST | `/api/auth/logout/` | `{"refresh"}` + header `Authorization: Bearer <access>` | Invalida el refresh (blacklist) y cierra la `UserSession` |
| GET | `/api/auth/me/` | — (header `Authorization: Bearer <access>`) | Perfil del usuario autenticado |

## Cómo retomar si esta sesión se corta

```bash
# 1. Verifica qué falta comparando con este documento (sección "Estado actual" arriba)
# 2. Si el código ya está todo en el servidor, solo falta probar:
curl -s -X POST http://127.0.0.1:8001/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "TU_USUARIO", "password": "TU_PASSWORD"}'

# Copia el "access" del resultado y prueba:
curl -s http://127.0.0.1:8001/api/auth/me/ \
  -H "Authorization: Bearer PEGA_EL_ACCESS_AQUI"

# 3. Si eso funciona, el backend de la Fase 2 esta completo.
#    Lo siguiente es el frontend: crear modules/auth/ (ver ARCHITECTURE.md
#    para la convencion de carpetas: views/, stores/, services/, routes.js)
```

## Próximo paso (frontend — pendiente de iniciar)

Crear `frontend/src/modules/auth/`:
- `services/authService.js` — llamadas axios a los 4 endpoints
- `stores/authStore.js` — Pinia: guarda `access`/`refresh` en memoria (no localStorage por seguridad XSS, evaluar httpOnly cookie a futuro), función `login()`, `logout()`, `fetchMe()`
- `views/LoginView.vue` — formulario simple, sin diseño pulido aún (eso es Fase 3+)
- `routes.js` — ruta `/login`
- Interceptor de axios global en `shared/utils/` para adjuntar el `Bearer` token y manejar el refresh automático en un 401
- Guard en `router/index.js`: redirige a `/login` si no hay sesión