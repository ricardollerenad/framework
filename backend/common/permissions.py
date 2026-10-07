from rest_framework.permissions import BasePermission

class HasRole(BasePermission):
    def has_permission(self, request, view):
        # 1. Validar que el usuario esté autenticado primero (evita errores con AnonymousUser)
        if not request.user or not request.user.is_authenticated:
            return False
        
        # 2. Obtener los roles permitidos definidos en la vista
        allowed_roles = getattr(view, 'allowed_roles', [])
        
        # 3. Verificar si el usuario pertenece a alguno de los grupos permitidos
        return request.user.groups.filter(name__in=allowed_roles).exists()