DROP TYPE IF EXISTS struct_ban_api_geoloc CASCADE ;
CREATE  TYPE struct_ban_api_geoloc AS (
    adresse character varying(150), -- Adresse de géolocalisation initiale (concaténation : [adresse]+" "+[code_com_etab]+" "+[nom_com_etab] ou adresse corrigée manuellement
    ban_adresse character varying(150), -- Adresse de géolocalisation retournée
    -- ban_geom_epsg2154 geometry(Point,2154), -- Géométrie du point de localisation (Point, projection Lambert 93 (Borne France) - EPSG 2154)
    -- ban_x_epsg2154 numeric, -- X du point de localisation (Point, projection Lambert 93 (Borne France) - EPSG 2154)
    -- ban_y_epsg2154 numeric, -- Y du point de localisation (Point, projection Lambert 93 (Borne France) - EPSG 2154)
    -- ban_geom_epsg4326 geometry(Point,2154), -- Géométrie du point de localisation (Point, projection WGS-84 (EPSG 4326)
    ban_x_epsg4326 numeric, -- X du point de localisation (Point, projection WGS-84 (EPSG 4326)
    ban_y_epsg4326 numeric, -- Y du point de localisation (Point, projection WGS-84 (EPSG 4326)
    ban_score numeric, -- Indice de confiance de la géolocalisation
    ban_precision integer, -- Degré de précision de la géolocalisation: du moins précis (5- à la commune) au plus précis (8– à l’adresse, voire 9- au bâtiment)
    ban_source character varying(25), -- Source ou origine de la géolocalisation (Gmaps, BAN, Observatoire…)
    ban_licence character varying(25), -- Licence d’utilisation (OdbL, autres…)
    ban_date date -- Date de la géolocalisation, quelle que soit son origine
   )
;

DROP FUNCTION IF EXISTS py_ban_geocoding(adresse text);
CREATE FUNCTION py_ban_geocoding(adresse text)
    RETURNS SETOF struct_ban_api_geoloc

  AS $$
  # Corps de la fonction PL/Python

    # Imports
    from datetime import datetime
    import requests
    import json

    # Constantes
    ban_api_search_endpoint = 'https://api-adresse.data.gouv.fr/search/'
    nb_resultat = 1

    # Déclaration des variables
    ban_adresse = None
    # ban_geom_epsg2154 = None
    # ban_x_epsg2154 = None
    # ban_y_epsg2154 = None
    # ban_geom_epsg4326 = None
    ban_x_epsg4326 = None
    ban_y_epsg4326 = None
    ban_score = None
    ban_precision = None
    ban_source = None
    ban_licence = None
    ban_date = datetime.now()


    # Création de la chaine qui sera envoyée à l'API
    payload = {'q': adresse, 'limit': nb_resultat}

    # Request auprès de l'API
    r = requests.get(ban_api_search_endpoint, params=payload)

    # Parsing de la réponse de l'API
    jresult = json.loads(r.text)
    # print(f'Retour: \n{jresult["features"][0]["properties"]["score"]}')

    ban_adresse = jresult["features"][0]["properties"]["label"]
    ban_score = round(jresult["features"][0]["properties"]["score"], 3)
    postcode = jresult["features"][0]["properties"]["postcode"]
    citycode = jresult["features"][0]["properties"]["citycode"]
    ban_x_epsg4326 = jresult["features"][0]["properties"]["x"]
    ban_y_epsg4326 = jresult["features"][0]["properties"]["y"]
    city = jresult["features"][0]["properties"]["city"]
    type = jresult["features"][0]["properties"]["type"]
    importance = jresult["features"][0]["properties"]["importance"]
    ban_source = jresult["attribution"]
    ban_licence = jresult["licence"]

    # Todo : Traitement des géo

    # Traitement de la précision
    if type in ('village', 'town', 'city', 'locality' ):
        ban_precision = 5
    elif type == 'street':
        ban_precision = 6
    elif type == 'housenumber':
        ban_precision = 9
    else :
        ban_precision = 5

    return [
        (
            adresse,
            ban_adresse,
            # ban_geom_epsg2154,
            # ban_x_epsg2154,
            # ban_y_epsg2154,
            # ban_geom_epsg4326,
            ban_x_epsg4326,
            ban_y_epsg4326,
            ban_score,
            ban_precision,
            ban_source,
            ban_licence,
            ban_date,
        )
    ]


$$ LANGUAGE plpython3u;