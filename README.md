# Семинар: развертывание отказоустойчивого приложения в Managed Service for Kubernetes®

# Требуемое окружение

Для самостоятельного выполнения работы необходимо настроить окружение самостоятельно.

Для выполнения практической работы:
1. Установите следующие утилиты:
* yc (https://cloud.yandex.ru/docs/cli/quickstart);
* Docker (https://docs.docker.com/get-docker/);
* Kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/);
* envsubst;
* git;
* ssh;
* curl.

2. Зарегистрироваться в Яндекс.Облаке (https://cloud.yandex.ru/);
3. Подключиться к облаку hse-design-students. 

# Проверка кластера K8S
## Шаг 1. Проверяем кластер
* Добавить переменные окружения
* Добавить учетные данные

### Добавление переменных окружения
1. На странице браузера, где создавалась группа узлов, проверьте, что создание группы завершено.
2. В терминале проверьте, что кластер доступен к использованию:
```
yc managed-kubernetes cluster list
echo "export K8S_ID=k8s-id-here" >> ~/.bashrc && . ~/.bashrc
echo $K8S_ID
yc managed-kubernetes cluster --id=$K8S_ID get
yc managed-kubernetes cluster --id=$K8S_ID list-node-groups
```

### Добавление учетных данных в конфигурационный файл Kubectl
```
yc managed-kubernetes cluster get-credentials --id=$K8S_ID --external
```
Конфигурация будет записана в файл `~/.kube/config`, проверим его содержимое:
```
cat ~/.kube/config
```

# Подготовка Docker-образов
## Шаг 2. Работаем с Docker
* Создать Container Registry
* Собрать Docker-образ

### Создание Container Registry
1. Создайте реестр: `yc container registry create --name {YOUR_NAME}`;
2. Сохраните id реестра:
```
echo "export REGISTRY_ID=registry-id-here" >> ~/.bashrc && . ~/.bashrc
```
2. Проверьте наличие реестра через терминал:
```
yc container registry list
yc container registry get $REGISTRY_ID
```

3. Настройте аутентификацию в docker:
```
yc container registry configure-docker
cat ~/.docker/config.json
```
Файл `config.json` содержит вашу конфигурацию после авторизации:
```
{
  "credHelpers": {
    "container-registry.cloud.yandex.net": "yc",
    "cr.cloud.yandex.net": "yc",
    "cr.yandex": "yc"
  }
}
```

### Сборка и загрузка Docker-образов в Container Registry
1. Перейдите к исходникам приложения:
```
cd $REPO/app && ls
```

2. Соберите образ приложения:
```
docker build . --tag cr.yandex/$REGISTRY_ID/order-app:v1
docker images
```

3. Загрузите образ
```
docker push cr.yandex/$REGISTRY_ID/order-app:v1
```

### Просмотр списка Docker-образов

1. Получите список Docker-образов в реестре командой `yc container image list`.
* В результате в таблице отборазятся ID образа, дата его создания и другие данные.

# Изолируем свое рабочее пространство
## Шаг 3.0. Создаем namespace
```
kubectl create namespace {YOUR_NAMESPACE}
kubectl config set-context --current --namespace={YOUR_NAMESPACE}
```

# Развертывание приложения и балансировщика нагрузки в k8s
## Шаг 3.1. Работаем с kubectl

1. Просмотрите файлы конфигурации:
```
cd $REPO/k8s-files/db && ls
```

2. Раверните базу данных:
```
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

3. Раверните приложение:
```
cd ../app
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

```
kubectl describe service order-app
```

5. Как только балансировщик нагрузки полноценно развернется и получит внешний URL (поле `LoadBalancer Ingress`),
проверим работоспособность сервиса в браузере.

# Обновление приложения
## Шаг 4. Изменения в сервисы и его выкатка (canary-deployment)
```
cd app
kubectl apply -f canary-deployment.yaml
kubectl get pods -l app=order-app
```

Необходимо убедиться, что новая версия сервиса работает корректно

```
kubectl scale deployment order-app-deployment-v1 --replicas=0
kubectl scale deployment order-app-deployment-v2 --replicas=3
kubectl get pods -l app=order-app
```


# Изменения в архитектуре сервиса для обеспечения отказоустойчивости
## Шаг 5. Изменения в архитектуре сервиса

После выполнения всех шагов имеем:
* Managed Kubernetes с зональным мастером (1 хост) и группой узлов из одного узла.
* одну реплику приложения, запущенную в k8s.

### Отказоустойчивый Managed Kubernetes

Необходимо создать региональный мастер, состоящий из трех хостов. Тип мастера уже созданного кластера
поменять нельзя, поэтому придется создать новый кластер.
1. Перейдите во вкладку `Managed Service for Kubernetes` и создайте новый кластер.
2. Выберите тип мастера `Региональный`.
3. Создайте группу узлов с тремя узлами.
4. Убедитесь, что у хостов в группе узлов достаточно ресурсов, чтобы обрабатывать возвросшую нагрузку при отказе одного
или нескольких хостов.

### Отказоустойчивое приложение

При развертывании приложения в k8s вы указывали одну реплику, теперь надо увеличить количество реплик до трех. Созданный
балансировщик нагрузки будет распределять нагрузку по всем трем репликам.

# Удаление ресурсов
## Шаг 6. Удаление ресурсов
* Удаление ресурсов из кластера k8s.  
* Удаление кластера k8s.  
* Удаление реестра и Docker-образов.  

### Удаление ресурсов из кластера k8s
```
cd app
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
cd ../db
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f pvc.yaml
```

### Удаление кластера k8s
```
yc managed-kubernetes cluster list
yc managed-kubernetes cluster delete lab-k8s
yc managed-kubernetes cluster list
```

### Удаление реестра и Docker-образов
Перейдите во вкладку `Container Registry` в Консоли, выберите реестр `lab-registry` и удалите в нем все образы.
После этого вернитесь к списку реестров, нажмите раскрывающееся меню для реестра `lab-registry` и удалите реестр.
