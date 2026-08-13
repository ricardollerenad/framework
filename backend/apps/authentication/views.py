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
    """Login estándar de Simple JWT, pero además registra la sesión para trazabilidad."""

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

        # Marca la sesion actual (la del access token con el que se autentico este request) como cerrada
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
