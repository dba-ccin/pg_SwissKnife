DROP TYPE IF EXISTS struct_ban_api_geoloc CASCADE ;
CREATE TYPE struct_ban_api_geoloc AS (
    adresse character varying, -- Adresse passée en paramètre
    query character varying, -- Adresse envoyée pour sa géolocalisation
    label character varying(150), -- Libellé complet de l’adresse retournée
    score numeric, -- Indice de confiance de la géolocalisation
    id character varying, -- identifiant de l’adresse (clef d’interopérabilité)
    type character varying, -- Type de résultat trouvé :
                                -- housenumber : numéro « à la plaque »
                                -- street : position « à la voie », placé approximativement au centre de celle-ci
                                -- locality : lieu-dit
                                -- municipality : numéro « à la commune »
    housenumber character varying(10), -- numéro avec indice de répétition éventuel (bis, ter, A, B)
    name character varying, --  Numéro éventuel et nom de voie ou lieu dit
    street character varying, --  Nom de voie
    postcode character varying(10), -- Code postal
    city character varying, -- Nom de la commune
    district character varying, -- Nom de l’arrondissement (Paris/Lyon/Marseille)
    -- oldcitycode character varying, -- Code INSEE de la commune ancienne (le cas échéant)
    -- oldcity character varying, -- Nom de la commune ancienne (le cas échéant)
    citycode character(5), -- Code INSEE de la commune
    context character varying, -- N° de département, nom de département et de région
    x_epsg4326 numeric, -- X du point de localisation (Point, projection WGS-84 (EPSG 4326)
    y_epsg4326 numeric, -- Y du point de localisation (Point, projection WGS-84 (EPSG 4326)
    importance character varying, -- indicateur d’importance (champ technique)
    attribution character varying(25), -- Source de la géolocalisation
    licence character varying(25), -- Licence d’utilisation (OdbL, autres…)
    date_geoloc date -- Date de la géolocalisation, quelle que soit son origine
   )
;

DROP FUNCTION IF EXISTS py_ban_row_geocoding(adresse text);
CREATE FUNCTION py_ban_row_geocoding(adresse text)
    RETURNS SETOF struct_ban_api_geoloc

  AS $$
  # Corps de la fonction PL/Python

    """
    Les coordonnées sont exprimées en WGS-84 (EPSG 4326)

    Les attributs retournés sont :
        adresse : adresse passée en paramètre
        query : adresse envoyée pour sa géolocalisation
        label : libellé complet de l’adresse retournée
        score : valeur de 0 à 1 indiquant la pertinence du résultat
        id : identifiant de l’adresse (clef d’interopérabilité)
        type : type de résultat trouvé
            housenumber : numéro « à la plaque »
            street : position « à la voie », placé approximativement au centre de celle-ci
            locality : lieu-dit
            municipality : numéro « à la commune »
        housenumber : (optionnel) numéro avec indice de répétition éventuel (bis, ter, A, B)
        name : (optionnel) numéro éventuel et nom de voie ou lieu dit
        street : (optionnel) nom de voie
        postcode : (optionnel) code postal
        city : (optionnel) nom de la commune
        district : (optionnel) nom de l’arrondissement (Paris/Lyon/Marseille)
        # oldcitycode : (optionnel) code INSEE de la commune ancienne (le cas échéant)
        # oldcity : (optionnel) nom de la commune ancienne (le cas échéant)
        citycode : (optionnel) code INSEE de la commune
        context : (optionnel) n° de département, nom de département et de région
        x_epsg4326 : coordonnées géographique en projection légale
        y_epsg4326 : coordonnées géographique en projection légale
        importance : indicateur d’importance (champ technique)
        attribution : source
        licence : licence d'utilistion des données de géolocalisation
        date_geoloc : date de la géolocalisation
    """

    # Imports
    from datetime import datetime
    import requests
    import json

    # Constantes
    ban_api_search_endpoint = 'https://api-adresse.data.gouv.fr/search/'
    nb_resultat = 1

    # Déclaration des variables
    query = None
    label = None
    score = None
    id = None
    type = None
    housenumber = None
    name = None
    street = None
    postcode = None
    city = None
    # district = None
    # oldcitycode = None
    # oldcity = None
    citycode = None
    context = None
    x_epsg4326 = None
    y_epsg4326 = None
    importance = None
    attribution = None
    licence = None
    date_geoloc = datetime.now()

    # Création de la chaine qui sera envoyée à l'API
    payload = {'q': adresse, 'limit': nb_resultat}

    # Request auprès de l'API
    r = requests.get(ban_api_search_endpoint, params=payload)

    # Parsing de la réponse de l'API
    jresult = json.loads(r.text)
    # print(f'Retour: \n{jresult["features"][0]["properties"]["score"]}')

    query = jresult["query"]
    label = jresult["features"][0]["properties"]["label"]
    score = round(jresult["features"][0]["properties"]["score"], 3)
    id = jresult["features"][0]["properties"]["id"]
    type = jresult["features"][0]["properties"]["type"]
    
    # Traitements des champs optionels
    # cf. https://github.com/geocoders/geocodejson-spec/tree/master/draft
    
    properties = jresult["features"][0]["properties"]
    
    for key in properties :
        if 'housenumber' in key:
            housenumber = jresult["features"][0]["properties"]["housenumber"]

        if 'name' in key:
            name = jresult["features"][0]["properties"]["name"]

        if 'street' in key:
            street = jresult["features"][0]["properties"]["street"]

        if 'postcode' in key:
            postcode = jresult["features"][0]["properties"]["postcode"]

        if 'city' in key:
            city = jresult["features"][0]["properties"]["city"]

        if 'district' in key:
            district = jresult["features"][0]["properties"]["district"]

        if 'citycode' in key:
            citycode = jresult["features"][0]["properties"]["citycode"]

        if 'context' in key:
            context = jresult["features"][0]["properties"]["context"]

    x_epsg4326 = jresult["features"][0]["properties"]["x"]
    y_epsg4326 = jresult["features"][0]["properties"]["y"]
    
    importance = jresult["features"][0]["properties"]["importance"]
    attribution = jresult["attribution"]
    licence = jresult["licence"]
    
    return [
        (
            adresse,
            query,
            label ,
            score ,
            id ,
            type ,
            housenumber ,
            name ,
            street ,
            postcode ,
            city ,
            district ,
            # oldcitycode ,
            # oldcity ,
            citycode ,
            context ,
            x_epsg4326 ,
            y_epsg4326 ,
            importance ,
            attribution ,
            licence ,
            date_geoloc,
        )
    ]


$$ LANGUAGE plpython3u;