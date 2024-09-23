# starting db
cd db
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
echo "App was created"
sleep 10
# starting app
cd ../app
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
