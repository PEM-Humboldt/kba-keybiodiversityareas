---
title: "Flujo de trabajo KBAs Instituto Humboldt"
author: 
  - name: "Rincon-Parra VJ"
    email: "rincon-v@javeriana.edu.co"
    affiliation: "Gerencia de información cientifica. Instituto de Investigación de Recursos Biológicos Alexander von Humboldt - IAvH"
  - name: "Karolina Fierro;"
    email: "kfierro@humboldt.org.co"
output: 
  github_document:
    md_extension: +gfm_auto_identifiers
    preserve_yaml: true
    toc: false
---

Flujo de trabajo KBAs Instituto Humboldt
================
truetrue

Este repositorio almacena códigos para estimar potenciales detonantes
KBA. El código principal
[KeyBiodiversityAreas_KBA.R](script/KeyBiodiversityAreas_KBA.R) permite
estimar potenciales detonantes KBA para polígonos dados. Los resultados
se presentan en una tabla de Excel que incluye las especies presentes en
el área de estudio y las proporciones de presencia de esas especies en
el sitio respecto a su distribución global, consideradas como umbrales
de evaluación KBA. Además, una segunda pestaña en el documento muestra
solo las especies que superan estos umbrales como potenciales detonantes
KBA. Las entradas de ejemplo de estos códigos están almacenadas en
[IAvH/Unidades
compartidas/KBA/estimateTriggersKBA](https://drive.google.com/open?id=17jAIW2WaRDFeX_d7gUmHWdLuWCrooJlh&usp=drive_fs).
Una vez descargadas, reemplaza la carpeta “input” en el directorio donde
está guardado el código correspondiente, con la carpeta “input” de la
descarga. El directorio del segundo código debe estar organizado de esta
manera que facilita la ejecución del código:

    script
    │- Script_VariationHumanFootprintSpecialAreas
    │    
    └-input
    │ │
    │ └- studyArea
    │ │   │
    │ │   │- studyArea.shp
    │ │
    │ │
    │ └- species_maps
    │ │   │
    │ │   │- catalogmaps_1
    │ │   │- ...
    │ │   │- catalogmaps_n
    │ │
    │ │
    │ └- grid_UICN
    │     │
    │     │- AOOGrid_2x2km.img
    │     
    │- data_Col_sp_IUCN_potential_triggers.xlsx
    │     
    └-output

La conservación de áreas importantes para la biodiversidad es
fundamental para la gestión ambiental y la sostenibilidad. Las Áreas
Clave para la Biodiversidad (KBA) son sitios prioritarios donde
convergen elementos significativos para la biodiversidad. Estas áreas
albergan proporciones importantes de unidades biológicas identificadas
mediante un protocolo estándar basado en criterios de distribución,
amenaza y convergencia de biodiversidad (IUCN, 2022).

Utilizamos mapas de distribución de todas las especies amenazadas y
restringidas de plantas y vertebrados listadas por la lista roja de la
[Unión Internacional para la Conservación de la Naturaleza –
IUCN](https://www.iucnredlist.org/search?landRegions=CO&searchType=species)
para Colombia. Aplicamos esta metodología sobre grillas de Colombia a
una escala de 1 km², y probamos los criterios en sitios de potencial
gestión ambiental, como áreas protegidas. Nuestra principal fuente de
información son los mapas de rango de distribución de especies
publicados en la plataforma de la IUCN (IUCN, 2022). También utilizamos
los mapas desarrollados para especies endémicas por
[Biomodelos](https://biomodelos.humboldt.org.co/), esenciales para la
estimación de umbrales KBA, ya que incluyen estimaciones para muchas
especies que no disponen de otras fuentes de información (IUCN, 2022).

Los mapas disponibles en la plataforma IUCN son archivos espaciales
vectorizados, cuyo análisis puede ser muy demandante en términos de
tiempo y recursos computacionales. Para abordar esta limitación, el
Instituto Humboldt implementó una metodología para el análisis de
potenciales especies detonantes mediante la organización de archivos
espaciales soportadas en catálogos JSON. Los archivos están acompañados
de archivos JSON que describen su fecha de publicación, taxonomía,
estado de amenaza, categoría de restricción y el dato del área global de
la especie estimado a partir de ese archivo espacial (IUCN, 2022). Un
sitio puede calificar como KBA si cumple con uno o más de los criterios
y umbrales detonantes (IUCN, 2022):

- A. Biodiversidad Amenazada
  - A1. Especies Amenazadas: Un sitio califica si cumple con uno de los
    siguientes umbrales:
    - 1)  ≥0.5% del tamaño de la población global y ≥5 unidades
          reproductivas de una especie en peligro crítico (CR) o en
          peligro (EN).
    - 2)  ≥1% del tamaño de la población global y ≥10 unidades
          reproductivas de una especie vulnerable (VU).
    - 3)  ≥0.1% del tamaño de la población global y ≥5 unidades
          reproductivas de una especie en peligro crítico (CR) o en
          peligro (EN) debido únicamente a la reducción del tamaño de la
          población en el pasado o presente.
    - 4)  ≥0.2% del tamaño de la población global y ≥10 unidades
          reproductivas de una especie vulnerable (VU) debido únicamente
          a la reducción del tamaño de la población en el pasado o
          presente.
    - 5)  La totalidad o casi la totalidad (efectivamente más del 95%)
          del tamaño de la población global de una especie en peligro
          crítico (CR) o en peligro (EN). A2. Tipos de Ecosistemas
          Amenazados: Un sitio califica si contiene un tipo de
          ecosistema amenazado según los criterios de la Lista Roja de
          Ecosistemas de la IUCN.
- B. Biodiversidad Geográficamente Restringida
  - B1. Especies Individualmente Restringidas Geográficamente: Un sitio
    califica si contiene al menos el 10% del tamaño de la población
    global de una especie restringida geográficamente.
  - B2. Co-ocurrencia de Especies Restringidas Geográficamente: Un sitio
    califica si contiene al menos el 1% de la población global de cada
    una de al menos dos especies restringidas geográficamente.
  - B3. Ensamblajes Restringidos Geográficamente: Un sitio califica si
    contiene una parte significativa de un ensamblaje de especies
    restringidas geográficamente.
  - B4. Tipos de Ecosistemas Restringidos Geográficamente: Un sitio
    califica si contiene al menos el 20% de la extensión global de un
    tipo de ecosistema restringido geográficamente.

## Referencias

[Guidelines for using A global standard for the identification of Key
Biodiversity Areas : version 1.2. IUCN, KBA Standards and Appeals
CommitteeIUCN Species Survival Commission (SSC)IUCN World Commission on
Protected Areas (WCPA)](https://portals.iucn.org/library/node/49979)
