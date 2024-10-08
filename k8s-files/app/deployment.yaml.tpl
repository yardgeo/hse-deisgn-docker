apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-app-deployment-v1
  labels:
    app: order-app
    version: v1
spec:
  replicas: 2  # Число реплик приложения
  selector:
    matchLabels:
      app: order-app
      version: v1
  template:
    metadata:
      labels:
        app: order-app
        version: v1
    spec:
      containers:
        - name: order-app
          image: cr.yandex/$REGISTRY_ID/order-app:v1
          ports:
            - containerPort: 80
          env:
            - name: DATABASE_URL
              value: "postgresql://postgres:password@postgres-service.$NAMESCPACE_ID.svc.cluster.local:5432/order"
