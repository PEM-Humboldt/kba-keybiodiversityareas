## Establecer parámetros de sesión ####
### Cargar librerias/paquetes necesarios para el análisis ####

#### Verificar e instalar las librerC-as necesarias ####
packagesPrev <- installed.packages()[,"Package"]  
packagesNeed <- librerias <- list("rstudioapi", "magrittr", "plyr", "rredlist", "grid", "terra", "sf", "raster", "pbapply", "sp")  # Define los paquetes necesarios para ejecutar el codigo
new.packages <- packagesNeed[!(packagesNeed %in% packagesPrev)]  # Identifica los paquetes que no están instalados
if(length(new.packages)) {install.packages(new.packages, binary = TRUE)}  # Instala los paquetes necesarios que no estC!n previamente instalados

#### Cargar librerias ####
lapply(packagesNeed, library, character.only = TRUE)  # Carga las librerías necesarias

## Establecer entorno de trabajo ####
dir_work <- this.path::this.path() %>% dirname()  # Establece el directorio de trabajo

### Definir entradas necesarias para la ejecución del análisis ####

# Definir la carpeta de entrada-insumos
input_folder<- file.path(dir_work, "input"); # "~/input"

# Crear carpeta output
output<- file.path(dir_work, "output"); dir.create(output)

####  Entradas basicas - mapas de distribucion ####
input <- list(
  grid_UICN= file.path(input_folder, "grid_UICN/AOOGrid_2x2km.img"), # ruta archivo grilla base UICN
  SpeciesDistributionMaps= list( # Lista de la ruta de los folders con colecciones de mapas y catalogos json de metadatos. Debe especificarse el nombre del folder y el tipo de datos espaciales que integra, ya sea gpkg o tif,. Las colecciones estan cargadas en formato +init=epsg:54034 que es el de UICN
    "biomodelos_ESH"= list(file.path(input_folder, "species_maps/BIOMODELOS_N2"), type= "tif"), # Biomodelos Nivel 2. Descargados desde http://geonetwork.humboldt.org.co/geonetwork/srv/spa/catalog.search#/metadata/0a1a6bdf-3231-4a77-8031-0dc3fa40f21b
    "iucn_range"= list(file.path(input_folder, "species_maps/IUCN_Rangos_Vector"), type= "gpkg"), # Rangos de UICN. Descargados desde  https://www.iucnredlist.org/
    "iucn_aoo"= list(file.path(input_folder, "species_maps/IUCN_AOO"), type= "tif")  # Mapas espacialziados de grilals AOO. Obtenidos desde https://www.iucnredlist.org/
  ),
  data_Col_sp_IUCN_potential_triggers= file.path(input_folder, "data_Col_sp_IUCN_potential_triggers.xlsx") # ruta de archivo con metadatos de especies IUCN
  )

####  Definir poligono area de estudio ####
input$studyArea<- file.path(input_folder, "studyarea", "19130San_Antonio_Forest_Km_18.shp")

####  Definir CRS de analisis ####
grid_UICN<- raster(input$grid_UICN)
crs_basemap<- crs(grid_UICN)

####  Cargar datos IUCN ####
data_Col_sp_IUCN_potential_triggers<- openxlsx::read.xlsx(input$data_Col_sp_IUCN_potential_triggers)


## Cargar colecciones de mapas ####
list_folders<- input$SpeciesDistributionMaps
list_collections<- pblapply(names(list_folders), function(x) {
  
  name_folder<- x
  dir_folder<- list_folders[[name_folder]][[1]]
  type_collection<- list_folders[[name_folder]][[2]]
  
  setwd(dir_folder)
  
  json_colleciton_file <- list.files(dir_folder, "\\.geojson$", recursive = TRUE, full.names = TRUE)
  catalog<- st_read(json_colleciton_file, crs= crs_basemap) %>% st_transform(crs_basemap)
  folder_layers<- list.files(dir_folder, pattern = "\\.json$", full.names = T, recursive = T)
  
  base_names<- tools::file_path_sans_ext(folder_layers) %>% basename
  
  json_data<- lapply(folder_layers, function(y) { rjson::fromJSON(file= y) })
  
  json_metadata <- pblapply(json_data, function(y) {
    as.data.frame(y$data) %>% dplyr::mutate(area_global_km2= y$area_km2, parameter= name_folder)
  }) %>% rbind.fill()
  
  json_layers <- pblapply(folder_layers, function(y) {
    json_data<- rjson::fromJSON(file= y)
    ext_file<- tools::file_ext(json_data$layer)
    if(ext_file %in% "gpkg"){st_read(json_data$layer, crs= crs_basemap) %>% st_transform(crs_basemap)}else{  file.path(dirname(y), json_data$layer)  }
  }) %>% setNames(base_names)
  
  
  list(folder= dir_folder, type=type_collection, catalog= catalog, metadata= json_metadata, layers= json_layers)
}) %>% setNames(names(list_folders))



## Cargar area de estudio ####
x<- sf::st_read(input$studyArea) %>% sf::st_transform(crs_basemap) %>% dplyr::mutate(ID_Site= tools::file_path_sans_ext(basename(input$studyArea)))


## Revision de especies en area de estudio ####
sf::sf_use_s2(FALSE)
ext_sp<-  st_bbox(x) %>% st_as_sfc() %>% st_transform(crs_basemap) %>% st_buffer(sqrt(prod(raster::res(grid_UICN)))) %>% st_bbox()
new_extent<- raster::alignExtent(ext_sp, grid_UICN, snap = "in")
base_sp<- raster( new_extent, crs= crs_basemap, res= raster::res(grid_UICN) )
base_grid<- grid_UICN %>% raster::crop(base_sp)
study_area_rast<-  fasterize::fasterize(x, raster(base_grid)) %>% terra::rast()


sp_intersect<- lapply(list_collections, function(y) {
  
  name_collection<- unique(y$metadata$parameter)
  type_collection <-   y$type
  folder_catalog<-   y$folder
  sp_catalog<-   y$catalog
  metadata_collection<-  st_drop_geometry(sp_catalog) %>% dplyr::mutate(parameter= name_collection) %>%
    dplyr::mutate(area_global_km2= area_km2) %>% dplyr::select(-area_km2)
  
  st_crs(x)
  
  check_extent<- unlist(st_intersects(x, sp_catalog ))
  check_sp_list<- sp_catalog[check_extent,] %>% st_drop_geometry()
  if(nrow(check_sp_list)>1){
    sp_extent<- y$layers[check_sp_list$scientific_name]
    area_intersect <-  {
      if(type_collection %in% "gpkg"){
        pblapply( names(sp_extent), function(y) { print(y) ; st_intersection(x, sp_extent[[y]]   ) %>%
            {data.frame(scientific_name= y, area_site_km2= sum(as.numeric(st_area(.)))/1000000)}}
        ) %>%
          rbind.fill()
      } else if(type_collection %in% "tif") {
        setwd(folder_catalog)
        sp_extent_rast<- pblapply(unlist(sp_extent), function(x) terra::rast(x) %>%
                                    terra::resample(study_area_rast)  %>% terra::mask(study_area_rast))  %>% terra::rast() %>%
          as.data.frame() %>% colSums(na.rm=T)   %>%
          {data.frame(scientific_name= names(.), area_site_km2= (.* (prod(res(study_area_rast))/1000000)) )}
      } }  %>% dplyr::filter(area_site_km2>0)
    sp_intersect_parameter<- list(area_intersect, metadata_collection) %>% plyr::join_all()
    sp_intersect_parameter} else {NULL}
}) %>% plyr::rbind.fill() %>% dplyr::select(-"layer")

## Estimacion de umbrales ####
species_site<- if (nrow(sp_intersect)>0){
  sp_intersect %>% dplyr::rowwise() %>%
    dplyr::mutate(area_perc_site= (area_site_km2/ area_global_km2)*100) %>%
    dplyr::mutate(area_perc_site= ifelse(area_perc_site>=95, 100, area_perc_site)) %>%
    list(data_Col_sp_IUCN_potential_triggers) %>% join_all()  %>% dplyr::rowwise() %>%
    dplyr::mutate(A= {if(!is.na(threatened)){
      if(category %in% c("CR", "EN")){
        if(area_perc_site >= 100){ "A1e"
        } else {
          if(area_perc_site>= 0.5) {"A1a"
          } else if ( (area_perc_site>= 0.1) & grepl("A1|A2|A4", criteria) ){ "A1c" } else {NA}
        }
      } else if(category %in% c("VU")){
        if(area_perc_site>= 1) {"A1b"
        } else if ( (area_perc_site>= 0.2) & grepl("A1|A2|A4", criteria) ){ "A1d" } else {NA}
      } else {NA}
    } else {NA} },
    B1= {if( (!is.na(endemic)) | (!is.na(restricted))  ){
      if(area_perc_site>= 10){"B1"}else{NA}
    } else {NA} }
    ) %>% split( (!is.na(.$B2_tax_group))& (.$area_perc_site>=1) ) %>%
    {list( if( "FALSE" %in% names(.) ){ mutate(.[["FALSE"]], B2=NA) }else{data.frame()},
           if( "TRUE" %in% names(.) ){
             .[["TRUE"]] %>%  split( .$B2_tax_group) %>%
               lapply(function(z) mutate(z, B2= ifelse(sum((!is.na(z$restricted))&( z$area_perc_site >= 1 ))>=unique(z$B2_nsp), "B2", NA))  ) %>%
               rbind.fill() }else{data.frame()}
    )} %>% rbind.fill() %>%
    dplyr::mutate(site_trigger= apply(.[c("A", "B1", "B2")], 1, function(x)
      if(all(is.na(unlist(x)))){NA}else{paste0(x[!is.na(x)], collapse = '')}   )  )
} else {NULL}


## Organizacion de datos - umbrales por especie ####
name_site<- unique(x$ID_Site)[1]

species_site_v2<- if(!is.null(species_site)){
  species_site %>% dplyr::mutate(sp= scientific_name, site= name_site) %>%
    dplyr::arrange(-area_perc_site)  %>%
    dplyr::relocate(c("category", "criteria", "parameter", "bias_aoo", "area_site_km2","area_global_km2","area_perc_site"), .before = "A") %>%
    dplyr::relocate(c("B2_tax_group", "B2_level", "B2_nsp"), .after = "amended_reason") }else{data.frame(site_trigger=NA)}

## Organizacion de datos - especies detonantes ####
triggers_site<- dplyr::filter(species_site_v2, !is.na(site_trigger))


## Exportar resultados ####
folder_site<- file.path(output, name_site )
dir.create(folder_site, recursive = T)
file_4326<- x %>% st_transform(4326)
centroid_data<- st_centroid(file_4326) %>% sf::st_coordinates() %>% as.data.frame() %>% dplyr::mutate(site= unique(x$site))
openxlsx::write.xlsx(list("triggers_site"= triggers_site, "species_site"= species_site_v2, centroid= centroid_data ), file = paste0(name_site, "_triggers.xlsx") )
st_write(x, paste0(name_site, ".gpkg"), delete_dsn = T )
st_write(x, paste0(name_site, ".shp") , delete_dsn = T  )

