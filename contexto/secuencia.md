# READ.ME

## Despliegue infraestructura

### PASO 1: Desplegar scripts y comprobar acceso 

```bash
	sudo ./01_crear.sh
	cd <carpeta>
	sudo ./02_deploy.sh
```  

### PASO 2: Desplegar superusuario

```bash
	sudo docker compose exec backend python manage.py createsuperuser
```  


### COMANDOS 
```html 
	cd <carpeta>/frontend && npm run build
	sudo docker compose restart <contenedor>
	sudo docker restart <contenedor>
	sudo docker compose logs -f --tail=10 <contenedor>

	docker exec -it <contenedor> python <script>
	sudo docker exec -it <contenedor> python manage.py makemigrations escolar
	sudo docker exec -it <contenedor> python manage.py migrate
	sudo docker exec -it <contenedor> python manage.py check

	sudo docker compose exec database pg_dump -U moodle_user moodle_db > backup_moodle_checkpoint_$(date +%Y%m%d_%H%M).sql
	sudo docker compose exec database pg_dump -U postgres -d django_db > backup_post_migracion_competencias_$(date +%Y%m%d_%H%M).sql

	sudo docker exec -it moodle_backend php /var/www/html/admin/cli/upgrade.php --non-interactive
	sudo docker exec -it moodle_backend php /var/www/html/admin/cli/purge_caches.php
```  
