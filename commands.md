sudo docker compose build
sudo docker compose up -d

docker compose ps

sudo docker compose down

docker compose exec db mysql -u root -p

<!-- github to dockerhub -->
docker login
sudo docker build -t new_dock_front https://github.com/Thanu10ekoon/DevOps_VoteX.git#main:client
sudo docker tag new_dock_front thanujaya10/new_dock_front:latest
sudo docker push thanujaya10/new_dock_front:latest

<!-- local to dockerhub -->
sudo docker login
sudo docker tag new_dock_front thanujaya10/new_dock_front:latest
sudo docker push thanujaya10/new_dock_front:latest
