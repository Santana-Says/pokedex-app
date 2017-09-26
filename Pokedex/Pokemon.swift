//
//  Pokemon.swift
//  Pokedex
//
//  Created by Jeffrey Santana on 9/24/17.
//  Copyright © 2017 Jeffrey Santana. All rights reserved.
//

import Foundation
import Alamofire

class Pokemon {
    private var _name: String!
    private var _pokedexId: Int!
    private var _description: String!
    private var _type: String!
    private var _defense: String!
    private var _height: String!
    private var _weight: String!
    private var _attack: String!
    private var _speed: String!
    private var _hp: String!
    private var _nextEvoId: String!
    private var _nextEvoName: String!
    private var _nextEvoLvl: String!
    private var _pokemonUrl: String!
    
    var name: String {
        return _name
    }
    
    var pokedexId: Int {
        return _pokedexId
    }
    
    var description: String {
        if _description == nil {
            _description = ""
        }
        return _description
    }
    
    var type: String {
        if _type == nil {
            _type = ""
        }
        return _type
    }
    
    var defense: String {
        if _defense == nil {
            _defense = ""
        }
        return _defense
    }
    
    var height: String {
        if _height == nil {
            _height = ""
        }
        return _height
    }
    
    var weight: String {
        if _weight == nil {
            _weight = ""
        }
        return _weight
    }
    
    var attack: String {
        if _attack == nil {
            _attack = ""
        }
        return _attack
    }
    
    var speed: String {
        if _speed == nil {
            _speed = ""
        }
        return _speed
    }
    
    var hp: String {
        if _hp == nil {
            _hp = ""
        }
        return _hp
    }
    
    var nextEvoId: String {
        if _nextEvoId == nil {
            _nextEvoId = ""
        }
        return _nextEvoId
    }
    
    var nextEvoName: String {
        if _nextEvoName == nil {
            _nextEvoName = ""
        }
        return _nextEvoName
    }
    
    var nextEvoLvl: String {
        if _nextEvoLvl == nil {
            _nextEvoLvl = ""
        }
        return _nextEvoLvl
    }
    
    init(name: String, pokedexId: Int) {
        _name = name
        _pokedexId = pokedexId
        
        _pokemonUrl = "\(URL_BASE)\(URL_POKEMON)\(_pokedexId)/"
    }
    
    func downloadPokemonDetails(completed: DownloadComplete) {
        let url = NSURL(string: _pokemonUrl)!
        Alamofire.request(.GET, url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                if let weight = dict["weight"] as? Int {
                    self._weight = "\(weight)"
                }
                
                if let height = dict["height"] as? Int {
                    self._height = "\(height)"
                }
                
                if let stats = dict["stats"] as? [Dictionary<String, AnyObject>] where stats.count > 0 {
                    for numStats in 0..<stats.count {
                        if let name = stats[numStats]["stat"]!["name"] as? String where name == "attack", let stat = stats[numStats]["base_stat"] as? Int {
                            self._attack = "\(stat)"
                        } else if let name = stats[numStats]["stat"]!["name"] as? String where name == "defense", let stat = stats[numStats]["base_stat"] as? Int {
                            self._defense = "\(stat)"
                        } else if let name = stats[numStats]["stat"]!["name"] as? String where name == "speed", let stat = stats[numStats]["base_stat"] as? Int {
                            self._speed = "\(stat)"
                        } else if let name = stats[numStats]["stat"]!["name"] as? String where name == "hp", let stat = stats[numStats]["base_stat"] as? Int {
                            self._hp = "\(stat)"
                        }
                    }
                }
                
                if let types = dict["types"] as? [Dictionary<String, AnyObject>] where types.count > 0 {
                    if let type = types[0]["type"]!["name"] {
                        self._type = type!.capitalizedString
                    }
                    if types.count > 1 {
                        for numTypes in 1..<types.count {
                            if let type = types[numTypes]["type"]!["name"] {
                                self._type! += "/\(type!.capitalizedString)"
                            }
                        }
                    }
                }
                
                if let speciesUrl = dict["species"]!["url"] as? String {
                    let nsUrl = NSURL(string: speciesUrl)!
                    Alamofire.request(.GET, nsUrl).responseJSON { response in
                        let result = response.result
                        
                        if let speciesDict = result.value as? Dictionary<String, AnyObject> {
                            if let entries = speciesDict["flavor_text_entries"] as? [Dictionary<String, AnyObject>] where entries.count > 0 {
                                for numEntries in 0..<entries.count {
                                    if let version = entries[numEntries]["version"]!["name"] as? String where version == "omega-ruby", let language = entries[numEntries]["language"]!["name"] as? String where language == "en" {
                                        if let description = entries[numEntries]["flavor_text"] as? String {
                                            self._description = description
                                        }
                                    }
                                }
                            }
                            
                            if let evoUrl = speciesDict["evolution_chain"]!["url"] as? String {
                                let nsUrl = NSURL(string: evoUrl)!
                                Alamofire.request(.GET, nsUrl).responseJSON { response in
                                    let result = response.result
                                    
                                    if let evoDict = result.value as? Dictionary<String, AnyObject> {
                                        if let chain = evoDict["chain"] as? Dictionary<String, AnyObject> {
                                            self.evolutionChain(chain)
                                        }
                                    }
                                    completed()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func evolutionChain(chain: Dictionary<String, AnyObject>) {
        if let evoName = chain["species"]!["name"] as? String where evoName != _name {
            if let nextEvo = chain["evolves_to"] as? [Dictionary<String, AnyObject>] where nextEvo.count > 0 {
                evolutionChain(nextEvo[0])
            }
        } else if let nextEvo = chain["evolves_to"] as? [Dictionary<String, AnyObject>] where nextEvo.count > 0 {
            if let evoName = nextEvo[0]["species"]!["name"] as? String where evoName.rangeOfString("mega") == nil {
                self._nextEvoName = evoName.capitalizedString
            }
            if let evoLvl = nextEvo[0]["evolution_details"]![0]["min_level"] as? Int  {
                self._nextEvoLvl = "\(evoLvl)"
            }else {
                self._nextEvoLvl = "Complicated"
            }
            if let url = nextEvo[0]["species"]!["url"] as? String {
                let newStr = url.stringByReplacingOccurrencesOfString("https://pokeapi.co/api/v2/pokemon-species/", withString: "")
                let num = newStr.stringByReplacingOccurrencesOfString("/", withString: "")
                self._nextEvoId = num
            }
        }
    }
}