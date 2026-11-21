## IN FRA E S TRUCTUR A PAR A TI · UTB · TALLE R PRÁCTICO

## Taller integrador: plataforma segura, escalable y altamente disponible

Caso CaribeShop: diseñar, desplegar como código y validar con pruebas de carga y de falla en Azure

Temas integrados:

Modalidad:

Herramientas:

Entrega:

Seguridad en la nube · Escalamiento automático · Alta disponibilidad · IaC · DevSecOps

Trabajo en grupo, fuera del aula

Azure · Terraform · GitHub Actions · Checkov · Locust

Repositorio + informe PDF + video


## 1. Contexto: CaribeShop prepara su temporada alta

CaribeShop es una tienda en línea con sede en Cartagena que se prepara para su campaña de fin de año. El año pasado la tienda se cayó dos veces: una por saturación durante una promoción y otra por la falla de su única máquina virtual. Además, una auditoría encontró la contraseña de la base de datos escrita en el repositorio y el puerto SSH abierto a Internet.

La gerencia contrató a su equipo para diseñar y desplegar en Azure una plataforma que sea segura, que escale automáticamente con la demanda y que siga funcionando cuando falle un componente, todo como código y con evidencia verificable.

## 1.1 Objetivos de aprendizaje

- Diseñar una arquitectura en la nube que integre controles de seguridad, escalamiento automático y alta disponibilidad.

- Implementarla completamente con Terraform y un pipeline DevSecOps en GitHub Actions.

- Validar empíricamente el comportamiento con pruebas de carga (Locust) y pruebas de falla.

- Analizar y justificar decisiones de diseño, riesgos aceptados y costos.

## 1.2 Condiciones

| Aspecto |   | Detalle |   |
| --- | --- | --- | --- |
| Modalidad |   | Grupos del proyecto de aula |   |
| Duración |   | Dos semanas a partir de la publicación en Savio |   |
| Entrega |   | Enlace al repositorio de GitHub + informe en PDF + video |   |
| Plataforma |   | Microsoft Azure (una suscripción de un integrante del grupo) |   |
| Punto de partida |   | Pueden reutilizar el código de las demostraciones (demo-seguridad y demo- escalamiento). El reto es integrarlas: no se acepta entregar las dos demos por separado |   |


## 2. Arquitectura objetivo

La arquitectura de referencia es el mínimo. Pueden reemplazar el Load Balancer por Application Gateway con WAF, agregar una base de datos administrada o usar contenedores, siempre que cumplan todos los requisitos de la sección 3 y justifiquen el cambio.


## 3. Requisitos

Cada requisito tiene un identificador que deben usar en el informe para referenciar su evidencia.

## Seguridad

| ID |   | Requisito |   | Evidencia mínima |   |
| --- | --- | --- | --- | --- | --- |
| S1 |   | Toda la infraestructura en Terraform. Estado en backend remoto (azurerm) y nunca en Git. Sin credenciales en el código. |   | Bloque backend, .gitignore, historial del repositorio limpio |   |
| S2 |   | Red: VNet con al menos una subred de aplicación; NSG de mínimo privilegio; ninguna VM con IP pública; SSH/RDP no expuestos a Internet. |   | Código del NSG + az vm list-ip- addresses / instancias del VMSS sin IP pública |   |
| S3 |   | La aplicación lee al menos un secreto desde Key Vault con identidad administrada del VMSS. Key Vault con RBAC, purge protection, firewall (subred + IP del operador) y secreto con expiración. |   | Endpoint de la app que demuestre la lectura sin mostrar el valor (p. ej. longitud o hash SHA-256 truncado) |   |
| S4 |   | Mínimo privilegio en roles: la identidad del VMSS solo puede leer secretos. |   | az role assignment list -- assignee <principal_id> |   |
| S5 |   | Al menos una Azure Policy con efecto Deny asignada por Terraform a su grupo de recursos. |   | Captura del error RequestDisallowedByPolicy al violarla |   |
| S6 |   | Diagnostic settings del Key Vault hacia Log Analytics. |   | Consulta KQL mostrando la lectura del secreto por la identidad del VMSS |   |

## Escalamiento y alta disponibilidad

| ID |   | Requisito |   | Evidencia mínima |   |
| --- | --- | --- | --- | --- | --- |
| E1 |   | VM Scale Set en al menos 2 zonas de disponibilidad, mínimo 2 instancias. Si su región no tiene zonas, justificar y usar la alternativa disponible. |   | Listado de instancias con su zona |   |
| E2 |   | Balanceador con sonda de salud sobre un endpoint dedicado. |   | Código de la sonda + métrica Health Probe Status |   |
| E3 |   | Autoscale con reglas de scale-out y scale-in con umbrales distintos (histéresis) y cooldowns justificados. ignore_changes = [instances] en el VMSS. |   | Código + historial de ejecución del autoscale |   |
| E4 |   | Reparación automática de instancias habilitada. |   | Código + evidencia de una instancia reemplazada |   |
| E5 |   | Al menos una alerta de Azure Monitor (p. ej. sonda por debajo de 100 % o CPU sostenida) con notificación por correo. |   | Correo recibido o captura del historial de alertas |   |


## DevSecOps

| ID |   | Requisito |   | Evidencia mínima |   |
| --- | --- | --- | --- | --- | --- |
| D1 |   | Workflow de GitHub Actions que en cada pull request ejecute terraform fmt -check, validate y Checkov bloqueante. |   | Ejecución exitosa + un PR donde el pipeline falle por un hallazgo introducido a propósito |   |
| D2 |   | Cada #checkov:skip debe tener una justificación escrita (riesgo aceptado). |   | Tabla de riesgos aceptados en el informe |   |
| D3 |   | Imagen o app reproducible: la VM se configura sola al arrancar (cloud- init o imagen), sin pasos manuales. |   | Código de cloud-init / Packer |   |


## 4. Pruebas obligatorias

## P1. Prueba de carga y escalamiento

- 1. Medir la capacidad de una instancia: con el autoscale en mínimo = máximo = 1 (temporalmente), aumentar usuarios en Locust hasta que el p95 supere 1 segundo. Registrar los RPS máximos sostenibles.

- 2. Restaurar el autoscale y ejecutar una prueba con perfil escalonado (subida, carga sostenida, bajada) de al menos 25 minutos, guardando CSV y reporte HTML: --csv y --html.

- 3. Evidenciar scale-out y scale-in: gráfico de instancias en el tiempo (historial de ejecución) junto al gráfico de RPS y p95 de Locust, alineados en el tiempo.

## P2. Pruebas de falla

- 1. Falla lógica: marcar una instancia como no sana (su /health responde 503) durante carga moderada. Medir cuánto tarda en dejar de recibir tráfico y cuántas peticiones fallaron.

- 2. Falla abrupta: eliminar una instancia durante carga moderada. Medir errores y tiempo hasta recuperar la capacidad mínima.

- 3. Reportar en ambos casos el porcentaje de error durante la ventana de la falla.

## P3. Pruebas de seguridad

- 1. Demostrar que el secreto no puede leerse desde una red no autorizada (p. ej. Cloud Shell) aunque el usuario tenga el rol.

- 2. Demostrar que una instancia no puede salir a un sitio arbitrario de Internet si implementaron filtrado de salida, o justificar por qué no lo implementaron.

- 3. Violar la política del requisito S5 y capturar el rechazo.

## Cuidado con la cuota y los créditos

Azure en algunas regiones limita los vCPU por región. Revisen az vm list-usage -l <region> -o table antes de fijar max_instances.

Las VMs de la serie B tienen créditos de CPU limitados: no dejen pruebas de carga corriendo sin supervisión.

Destruyan los recursos cuando terminen de recoger evidencias. Un despliegue olvidado consume el crédito de todo el semestre.


## 5. Entregables

## 5.1 Repositorio de GitHub

- Código Terraform organizado (variables, outputs, sin valores sensibles), aplicación y locustfile.py.

- Workflow en .github/workflows/ y al menos dos pull requests cerrados (uno que falla por seguridad y su corrección).

- README.md con: arquitectura, cómo desplegar y destruir, variables requeridas y checklist de la línea base de seguridad marcado.

- Carpeta evidencias/ con CSV y reportes HTML de Locust.

## 5.2 Informe (PDF, máximo 12 páginas sin contar anexos)

- 1. Diagrama de arquitectura y decisiones de diseño justificadas.

- 2. Tabla de trazabilidad: requisito (S1…D3) → archivo/recurso de Terraform → evidencia.

- 3. SLA compuesto estimado de su arquitectura, con el cálculo.

- 4. Resultados de P1, P2 y P3 con gráficos y análisis (no solo capturas).

- 5. Tabla de riesgos aceptados (incluye cada #checkov:skip) con impacto y mitigación.

- 6. Estimación de costo mensual si la plataforma corriera en producción (Calculadora de precios de Azure) y cómo lo reduciría el autoscale.

- 7. Respuestas a las preguntas de análisis (sección 6).

## 5.3 Video (6-8 minutos)

Demostración en vivo: despliegue ya realizado, prueba de carga mostrando la aparición de una nueva instancia y una prueba de falla. Todos los integrantes deben participar. Deben realizar una llamada grupal en Teams y grabar la sesión. Luego ese video lo deben subir a Youtube (acceso público) y enviar el enlace al video.


## 6. Preguntas de análisis

- 1. Con la capacidad medida por instancia, ¿cuántas instancias necesitaría CaribeShop para soportar 300 peticiones por segundo con p95 menor a 500 ms? ¿Es viable con su cuota actual? ¿Qué cambiaría?

- 2. Su autoscale tardó cierto tiempo en reaccionar (medirlo). Si la campaña genera un pico súbito a las 8:00 p. m., ¿cómo ajustaría la configuración? Considere perfiles programados y autoscale predictivo.

- 3. ¿Qué componente es ahora el punto único de falla de su arquitectura? ¿Cuánto costaría eliminarlo?

- 4. Si un atacante obtuviera ejecución de código en una instancia, ¿qué podría y qué no podría hacer, dados sus controles? Recorra las capas de defensa.

- 5. ¿Por qué el escaneo en el pipeline no sustituye a Azure Policy, ni viceversa?

- 6. El estado de Terraform contiene secretos. Describa cómo lo protegieron y qué pasaría si se filtrara.


## 7. Rúbrica de evaluación

| Criterio |   | Peso |   | Excelente (100 %) |   | Aceptable (60 %) |   | Insuficiente (0-30 %) |   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IaC y estado (S1, D3) |   | 10 % |   | Todo en Terraform, modular, backend remoto, sin pasos manuales |   | Terraform completo con algunos pasos manuales o estado local |   | Recursos creados a mano o credenciales en el código |   |
| Red y acceso (S2) |   | 10 % |   | NSG mínimo, sin IP pública ni SSH expuesto, egress controlado |   | Sin IP pública pero reglas más amplias de lo necesario |   | Puertos de administración expuestos |   |
| Identidad y secretos (S3, S4) |   | 15 % |   | Identidad administrada, rol de solo lectura, firewall, expiración, prueba negativa |   | Lectura desde Key Vault con permisos excesivos o sin firewall |   | Secretos en código, variables o cloud-init |   |
| Gobierno y observabilidad (S5, S6, E5) |   | 10 % |   | Política Deny demostrada, KQL de accesos, alerta funcionando |   | Faltan uno de los tres elementos |   | Faltan dos o más |   |
| Escalamiento (E3, P1) |   | 15 % |   | Histéresis justificada, capacidad medida, scale-out y scale-in evidenciados y analizados |   | Autoscale funcionando con evidencia parcial |   | Sin autoscale o sin evidencia |   |
| Alta disponibilidad (E1, E2, E4, P2) |   | 15 % |   | Multi-zona, sonda dedicada, reparación, fallas medidas con % de error |   | Multi-zona y sonda, pruebas de falla sin medición |   | Una sola instancia o una sola zona sin justificación |   |
| DevSecOps (D1, D2) |   | 10 % |   | Pipeline bloqueante, PR fallido y corregido, riesgos aceptados documentados |   | Pipeline que escanea pero no bloquea |   | Sin pipeline |   |
| Informe, análisis y video |   | 15 % |   | Trazabilidad completa, SLA compuesto, respuestas argumentadas con datos propios |   | Informe descriptivo con análisis limitado |   | Solo capturas sin análisis |   |


## 8. Plan de trabajo sugerido

| Días |   | Actividad |   |
| --- | --- | --- | --- |
| 1-2 |   | Diseño de la arquitectura, reparto de tareas, repositorio, backend remoto y pipeline base (fmt, validate, Checkov) |   |
| 3-5 |   | Red, VMSS multi-zona, balanceador, sonda y autoscale (partir de demo-escalamiento) |   |
| 6-7 |   | Key Vault, identidad administrada del VMSS, endpoint de la app que lee el secreto, firewall y diagnósticos (partir de demo-seguridad) |   |
| 8 |   | Azure Policy, alerta y endurecimiento final; corregir hallazgos de Checkov |   |
| 9-10 |   | Pruebas P1, P2 y P3, recolección de evidencias y destrucción de recursos |   |
| 11-14 |   | Informe, video y revisión cruzada entre integrantes |   |

## 8.1 Pistas de integración

- Al VMSS se le asigna identidad con un bloque identity { type = "SystemAssigned" }; el rol se asigna a azurerm_linux_virtual_machine_scale_set.<nombre>.identity[0].principal_id.

- La app puede obtener el token igual que el script leer-secreto.sh de la demo: una petición a IMDS (169.254.169.254) y luego la llamada al Key Vault. En Python se puede hacer con urllib sin instalar dependencias.

- Si filtran la salida con el NSG, recuerden permitir lo que la app necesita (AzureKeyVault) y que las sondas del balanceador entran por la etiqueta AzureLoadBalancer.

- La subred del VMSS debe tener el service endpoint Microsoft.KeyVault para poder incluirla en el firewall del Key Vault.

- No muestren nunca el valor del secreto en la app ni en los logs: muestren una huella (longitud o hash truncado).


## 9. Lista de verificación antes de entregar

- checkov -d . sin hallazgos fallidos; cada skip justificado.

- Ningún terraform.tfstate, .tfvars con datos reales ni secreto en el historial de Git.

- Ninguna VM con IP pública; ningún puerto 22/3389 abierto a Internet.

- Evidencias de scale-out, scale-in, falla lógica y falla abrupta con métricas.

- Evidencia de la política Deny, la consulta KQL y la alerta.

- Informe con trazabilidad, SLA compuesto, riesgos aceptados, costos y respuestas.

- Video de 6-8 minutos con participación de todos.

- Recursos de Azure destruidos (terraform destroy) y verificado en el portal. y
