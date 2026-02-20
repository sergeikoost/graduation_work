Graduation work for Netology DevOps course


## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.



### В целом диполмный проект выглядит так:

~~~
 graduation_work/
│
├── ya_cloud/
│   ├── init/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   │
│   ├── network/
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   │
│   └── README.md
│
├── k8s-cluster/
├── monitoring/
├── app/
└── ci-cd/
~~~

Все манифесты будут лежать в этом репозитории для проверок.


## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

**Ответ**

Terraform нельзя сразу использовать с удалённым backend, потому что сам backend (S3 bucket) тоже нужно где-то создать. Поэтому инфраструктура разделена на два независимых Terraform-проекта:
 1. init - bootstrap-конфигурация, создает сервисный аккаунт и bucket для хранения state.
 2. network - основная инфраструктура, создает VPC и подсети и хранит свой state уже в Object Storage.


terrform init в директории init, создаем ресурсы:

<img width="1040" height="295" alt="netology_gradu 1" src="https://github.com/user-attachments/assets/e1a2ffc1-78ac-4b7e-b544-fe25411c9ee0" />



 После init производится настройка удаленного backend.

Получаем ключи:

~~~
 export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
~~~

Настраиваем бэкэнд:

~~~
terraform init \
  -backend-config="bucket=<bucket>" \
  -backend-config="key=network/terraform.tfstate" \
  -backend-config="region=ru-central1" \
  -backend-config="endpoint=https://storage.yandexcloud.net"
~~~
<img width="895" height="366" alt="netology_gradu 2" src="https://github.com/user-attachments/assets/f0b5e3bc-d65c-49c1-8af1-31d2b5d5e95d" />


### Как результат - подготовлена базовая облачная инфраструктура:
1) настроен Terraform
2) реализован удалённый state
3) создана сеть (VPC)
4) созданы 3 подсети в разных зонах
5) инфраструктура воспроизводима (apply/destroy)

Эта сеть далее используется для Kubernetes-кластера, мониторинга и CI/CD.

### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.


 Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  Я решил воспользоваться им.

