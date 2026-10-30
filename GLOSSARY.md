# ComfyList

App de TODOs y citas con recordatorios, sincronizada entre dispositivos a través de la cuenta del usuario. Este glosario fija el vocabulario del proyecto.

## Sincronización

**Colección sondeada**:
Conjunto de elementos de la cuenta (las listas, las tareas de una lista, las citas o la papelera) que la app mantiene al día consultándolo cada cierto tiempo y tras cada cambio propio.
_Avoid_: watcher, stream en vivo, colección en vivo

**Registro de sondeo**:
Lugar donde se apuntan todas las colecciones sondeadas para pausarlas y reanudarlas a la vez cuando la app pasa a segundo plano o vuelve a primero.
_Avoid_: pauseAll, gestor de watchers
