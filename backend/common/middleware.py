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
