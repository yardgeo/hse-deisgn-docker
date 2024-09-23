# deleting app
cd app
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

# deleting db
cd ../db
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f pvc.yaml
