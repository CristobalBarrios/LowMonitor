# LowMonitor

Aplicación de diagnóstico y monitorización de hardware desarrollada en ensamblador x86-64 para el curso Arquitectura de Computadoras II.

## Estado del proyecto

LowMonitor se encuentra en desarrollo. Actualmente el repositorio todavía no contiene el código fuente, el Makefile ni un binario ejecutable. Las instrucciones siguientes definen el entorno y la forma prevista de compilar y ejecutar la aplicación cuando esos archivos estén disponibles.

## Funcionalidad prevista

La aplicación incluirá los siguientes módulos:

1. Identificación del CPU.
2. Monitor de puertos de entrada/salida.
3. Diagnóstico de memoria.
4. Monitor de rendimiento del CPU.
5. Gestión jerárquica de memoria.
6. Operaciones SIMD como funcionalidad opcional.

## Requisitos

- Procesador Intel o AMD con arquitectura x86-64.
- Linux de 64 bits. El enunciado del proyecto solicita Ubuntu 26.04 o posterior.
- NASM 2.15 o posterior.
- GNU `ld`, incluido en el paquete `binutils`.
- GNU Make.
- GDB, recomendado para depuración.
- Git, necesario para trabajar con el repositorio.

La aplicación no está diseñada para Windows ni para procesadores ARM. Ubuntu instalado en una máquina virtual permite desarrollar los módulos básicos, aunque el hipervisor puede limitar el acceso a puertos físicos y alterar las mediciones de rendimiento y memoria.

## Instalación de herramientas en Ubuntu

Actualizar el índice de paquetes:

```bash
sudo apt update
```

Instalar las herramientas requeridas:

```bash
sudo apt install nasm binutils make gdb git file util-linux
```

Comprobar el entorno:

```bash
cat /etc/os-release
uname -m
nasm -v
ld --version | head -n 1
make --version | head -n 1
```

La arquitectura mostrada por `uname -m` debe ser `x86_64` y la versión de NASM debe ser 2.15 o posterior.

## Obtener el proyecto

Clonar el repositorio y entrar en su directorio (Clonación a través de SSH):

```bash
git clone git@github.com:CristobalBarrios/LowMonitor.git
cd LowMonitor
```

Si el repositorio ya está clonado, solo es necesario abrir una terminal en la carpeta `LowMonitor`.

## Compilación

Cuando el Makefile esté implementado, compilar desde la raíz del repositorio con:

```bash
make
```

El proceso de compilación deberá ensamblar el código en formato ELF64, enlazarlo y generar el ejecutable en el directorio `build/`.

Para eliminar archivos generados:

```bash
make clean
```

## Ejecución

Después de compilar, ejecutar la aplicación desde la raíz del repositorio:

```bash
./build/lowmonitor
```

El Makefile también deberá ofrecer el comando equivalente:

```bash
make run
```
