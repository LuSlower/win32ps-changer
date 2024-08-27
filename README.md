# win32ps-changer
get or calculate the value of Win32PrioritySeparation

[![Total Downloads](https://img.shields.io/github/downloads/LuSlower/win32ps-changer/total.svg)](https://github.com/LuSlower/win32ps-changer/releases) [![PayPal Badge](https://img.shields.io/badge/PayPal-003087?logo=paypal&logoColor=fff&style=flat)](https://paypal.me/eldontweaks) 

![image](https://github.com/user-attachments/assets/8695e78b-af1d-44ee-9c1a-037d85002b2e)

> Win32PrioritySeparation is a registry value that allows you to adjust how Windows distributes CPU time between foreground processes and background processes.

This value determines the processor's time optimization strategy, affecting the duration and relative priority of foreground and background threads.

But what is it exactly?

`Win32PrioritySeparation` is a 6-bit mask (AABBCC), where each pair of bits controls a different aspect of the processor's timing optimization strategy

highest bits (AA)
specify the duration of the interval
This can be short or long (short or long)

the middle bits (BB)
specify the length of the interval
This can be variable or fixed (variable or fixed)

The first 4 bits divide their values ​​into this quantum table:

| Dur/Leng |  Short   |    Long    |
|----------|----------|------------|
| Variable | 06 12 18 | 12 24 36   |
| Fixed    | 18 18 18 | 36 36 36   |

lowest bits (CC)
specify the processor time optimization strategy that should be distributed between the foreground and background threads

this can be:

Equal and fixed (1:1). Foreground and background threads get the same processor time at fixed intervals.

2:1 ratio. Foreground threads get twice as much processor time as background threads.

3:1 ratio. Foreground threads get three times more processor time than background threads. 

priority separation can vary depending on the value you specify, a fixed quantum would completely nullify priority separation between threads

The best known way to manage this is by going to `sysdm.cpl>settings>advanced` 

![image](https://github.com/LuSlower/Win32Ps-Changer/assets/148411728/b110a7e4-7c5f-4be6-b30d-58b20c8ad995)

_Background Services_
2(2), default, default, 3:1

bitmask = 000010

foregroundquantum = _36 units_

backgroundquantum = _36 units_

apparently this has nothing to do with 3:1
in windows server, because the interval is fixed that overrides the `PsPrioritySeparation` of the quanta,
although it is also taken as a boost for the current priority of foreground processes

```
lkd> dt _KPROCESS ffffa78530811080 -n QuantumReset nt!_KPROCESS //dwm
+0x281 QuantumReset : 36 '$'
lkd> dt _KPROCESS ffffa7852c0ec080 -n QuantumReset nt!_KPROCESS //windbg
+0x281 QuantumReset : 36 '$'
lkd> db PspForegroundQuantum 13
fffff801`1fb63574 24 24 24
lkd> dd PsPrioritySeparation 11
fffff801`1fb2c9d8 00000002
```

_Programs_
26(38), short, variable, 3:1

bitmask = 010110

foregroundquantum = _18 units_

backgroundquantum = _6 units_

here it seems we can see a 3:1, similarly the quanta are fixed but the `PsPrioritySeparation` is applied, because the length is variable

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

thanks to the information from:
https://learn.microsoft.com/en-us/previous-versions/cc976120(v=technet.10)?redirectedfrom=MSDN

It can be stated that the maximum supported value is 3F (111111)
If any value exceeds the maximum, only the 6 least significant bits (LSB) can be read, which in short would be the 6 bits that start from right to left.

![image](https://github.com/user-attachments/assets/32b0d87f-454c-457e-a6e9-4944c6121402)









