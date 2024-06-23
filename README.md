# win32ps-changer
pequeño form powershell  para obtener o calcular el valor de Win32PrioritySeparation

[![Total Downloads](https://img.shields.io/github/downloads/LuSlower/win32ps-changer/total.svg)](https://github.com/LuSlower/win32ps-changer/releases) [![PayPal Badge](https://img.shields.io/badge/PayPal-003087?logo=paypal&logoColor=fff&style=flat)](https://paypal.me/eldontweaks) 

![image](https://github.com/LuSlower/Win32Ps-Changer/assets/148411728/5df94fae-3034-49f3-b20a-92c46811f65c)

> Win32PrioritySeparation es un valor del Registro que permite ajustar cómo Windows distribuye el tiempo de CPU entre los procesos en primer plano y los procesos en segundo plano.

Este valor determina la estrategia de optimización del tiempo del procesador, afectando la duración y la prioridad relativa de los subprocesos en primer plano y en segundo plano.

pero que es exactamente?

`Win32PrioritySeparation` es una máscara de 6 bits (AABBCC), donde cada par de bits controla un aspecto diferente de la estrategia de optimización del tiempo del procesador

los bits más altos (AA)
específican la duración del intervalo
este puede ser corto o largo (short or long)

los bits del medio (BB)
específican la longitud del intervalo
este puede ser variable o fijo (variable or fixed)

los primeros 4 bits dividen sus valores en esta tabla cuántica:

| Dur/Long |  Corto   |  Largo     |
|----------|----------|------------|
| Variable | 06 12 18 | 12 24 36  |
| Fijo     | 18 18 18 | 36 36 36  |

los bits más bajos (CC)
específican la estrategia de optimización de tiempo de procesador que se debe repartir entre los subprocesos de primer y segundo plano

este puede ser:

Iguales y fijos (1:1). Los subprocesos en primer plano y en segundo plano obtienen el mismo tiempo de procesador con intervalos fijos.

Relación 2:1. Los subprocesos en primer plano obtienen el doble de tiempo de procesador que los subprocesos en segundo plano.

Relación 3:1. Los subprocesos en primer plano obtienen tres veces más tiempo de procesador que los subprocesos en segundo plano. 

la separación de prioridad puede variar dependiendo del valor que específiquen, un quantum fijo (fixed) anularía completamente la separación de prioridad entre subprocesos 

la forma más conocida de administrar esto es yendo a `sysdm.cpl>settings>advanced` 

![image](https://github.com/LuSlower/Win32Ps-Changer/assets/148411728/b110a7e4-7c5f-4be6-b30d-58b20c8ad995)

_Background Services_
2(2), default, default, 3:1

bitmask = 000010

foregroundquantum = _36 unidades_

backgroundquantum = _36 unidades_

al parecer esto no tiene nada de 3:1
en windows server, por que el intervalo es fijo eso anula la `PsPrioritySeparation`

```
lkd> dt _KPROCESS ffffa78530811080 -n QuantumReset nt!_KPROCESS //dwm
+0x281 QuantumReset : 36 '$'
lkd> dt _KPROCESS ffffa7852c0ec080 -n QuantumReset nt!_KPROCESS //windbg
+0x281 QuantumReset : 36 '$' 1kd> db PspForegroundQuantum 13
fffff801`1fb63574 24 24 24
lkd> dd PsPrioritySeparation 11
fffff801`1fb2c9d8 00000002
```

Programs
26(38), corto, variable, 3:1

bitmask = 010110

foregroundquantum = 18 unidades

backgroundquantum = 6 unidades

aquí al parecer si podemos apreciar un 3:1, análogamente los cuantos son fijos pero la `PsPrioritySeparation` si es aplicada, debido a que la longitud es variable 

```
lkd> dt _KPROCESS ffffa78530811080 -n QuantumReset nt!_KPROCESS //dwm
+0x281 QuantumReset : 6
lkd> dt _KPROCESS ffffa7852c0ec080 -n QuantumReset nt!_KPROCESS //windbg
+0x281 QuantumReset : 18
lkd> db PspForegroundQuantum 13
fffff801`1fb63574 06 0c 12
lkd> dd PsPrioritySeparation 11
fffff801`1fb2c9d8 00000002
```

gracias a la información de:
http://systemmanager.ru/win2k_regestry.en/29623.htm

> (ya que en msdn fue borrado)

se puede afirmar que el valor máximo admitido es 3F (111111)
si algún valor sobrepasa el máximo solo podrán leerse los 6 bits menos significativos (LSB), que en pocas palabras serían los 6 bits que comienzan de derecha a izquierda 

![image](https://github.com/LuSlower/Win32Ps-Changer/assets/148411728/8a544a45-f67f-4c3c-acec-0cdb850c2f7c)








