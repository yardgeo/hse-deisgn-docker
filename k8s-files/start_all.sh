# starting db
cd db
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# starting app
cd ../app
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
