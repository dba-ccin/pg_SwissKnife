

## Mettre en place une fonction en PL-Python 
    qui retourne les info de géocodage de l'adresse passée en paramètre
    
    Todo : renvoyer directement des données préparées comme la geom en 2154, 3857...

## Utilisation 
### Générique

    SELECT * FROM ma_fonction('mon adresse à géocoder);

### Maj d'un tuple
    UPDATE ma_table AS d
    SET geom = st_geomfromtext('POINT (' || s.ban_x_epsg4326 || ' ' || s.ban_y_epsg4326 || ')', 4326)
    FROM (
        SELECT * FROM ma_fonction('mon adresse à géocoder)
        ) AS S
    WHERE s.id = d.id
    ;

## Mise en oeuvre

### Pré-requis
Cette fonction nécesssite 
- python3 
- la librairie 'requests'  (cf. https://docs.python-requests.org)
- python3 comme language procédural pour PostGreSQL (cf. https://www.postgresql.org/docs/current/plpython.html)

### Installations des prérequis
Pour Debian/ubuntu

    apt-get install python3-requests postgresql-plpython3-xx
avec xx correspondant à votre version de PostGreSQL

### Installation du support de python3 pour un base de données

Dans une base existante, 

    CREATE EXTENSION plpython3u;
    
### Création de type et de la fonction

    cf. api_ban_geloloc.sql

### Testing
    SELECT * from py_ban_geocoding('7 rue jeanne d''Arc Rouen');

|adresse|ban_adresse|ban_x_epsg4326|ban_y_epsg4326|ban_score|ban_precision|ban_source|ban_licence|ban_date|
|--------|--------|--------|--------|--------|--------|--------|--------|--------|
|7 rue jeanne d'Arc Rouen|7 Rue Jeanne d’Arc 76000 Rouen|561388.56|6928422.15|0.979|9|BAN|ETALAB-2.0|2021-07-20|


Enjoy !!!