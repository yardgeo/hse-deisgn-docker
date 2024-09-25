apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-app-deployment-v2
  labels:
    app: order-app
    version: v2
spec:
  replicas: 1  # Число реплик приложения
  selector:
    matchLabels:
      app: order-app
      version: v2
  template:
    metadata:
      labels:
        app: order-app
        version: v2
    spec:
      containers:
        - name: order-app
          image: cr.yandex/$REGISTRY_ID/order-app:v2
          ports:
            - containerPort: 80
          env:
            - name: DATABASE_URL
              value: "postgresql://postgres:password@postgres-service.$NAMESCPACE_ID.svc.cluster.local:5432/order"
