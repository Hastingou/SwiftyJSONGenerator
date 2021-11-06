//
//  SwiftyJSONModel.swift
//  SwiftyJSONAccelerator
//
//  Created by Karthikeya Udupa on 02/06/16.
//  Copyright © 2016 Karthikeya Udupa K M. All rights reserved.
//

import Foundation

/**
 *  Provides support for SwiftyJSON library.
 */
struct SwiftyJSONModelFile: ModelFile, DefaultModelFileComponent {

    var fileName: String
    var type: ConstructType
    var component: ModelComponent
    var sourceJSON: JSON
    var configuration: ModelGenerationConfiguration?

    // MARK: - Initialisers.
    init() {
        self.fileName = ""
        type = ConstructType.structType
        component = ModelComponent.init()
        sourceJSON = JSON.init([])
    }

    mutating func setInfo(_ fileName: String, _ configuration: ModelGenerationConfiguration) {
        self.fileName = fileName
        type = configuration.constructType
        self.configuration = configuration
    }

    func moduleName() -> String {
        return "SwiftyJSON"
    }

    func baseElementName() -> String? {
        return nil
    }

    func mainBodyTemplateFileName() -> String {
        return "SwiftyJSONTemplate"
    }

    mutating func generateAndAddComponentsFor(_ property: PropertyComponent) {
        switch property.propertyType {
        case .valueType:
            component.stringConstants.append(genStringConstant(property.constantName, property.key))
            component.initialisers.append(genInitializerForVariable(property.name, property.type, property.constantName))
            component.declarations.append(genVariableDeclaration(property.name, property.type, false))
            component.description.append(genDescriptionForPrimitive(property.name, property.type, property.constantName))
            component.decoders.append(genDecoder(property.name, property.type, property.constantName, false))
            component.encoders.append(genEncoder(property.name, property.type, property.constantName))
        case .valueTypeArray:
            component.stringConstants.append(genStringConstant(property.constantName, property.key))
            component.initialisers.append(genInitializerForPrimitiveArray(property.name, property.type, property.constantName))
            component.declarations.append(genVariableDeclaration(property.name, property.type, true))
            component.description.append(genDescriptionForPrimitiveArray(property.name, property.constantName))
            component.decoders.append(genDecoder(property.name, property.type, property.constantName, true))
            component.encoders.append(genEncoder(property.name, property.type, property.constantName))
        case .objectType:
            component.stringConstants.append(genStringConstant(property.constantName, property.key))
            component.initialisers.append(genInitializerForObject(property.name, property.type, property.constantName))
            component.declarations.append(genVariableDeclaration(property.name, property.type, false))
            component.description.append(genDescriptionForObject(property.name, property.constantName))
            component.decoders.append(genDecoder(property.name, property.type, property.constantName, false))
            component.encoders.append(genEncoder(property.name, property.type, property.constantName))
        case .objectTypeArray:
            component.stringConstants.append(genStringConstant(property.constantName, property.key))
            component.initialisers.append(genInitializerForObjectArray(property.name, property.type, property.constantName))
            component.declarations.append(genVariableDeclaration(property.name, property.type, true))
            component.description.append(genDescriptionForObjectArray(property.name, property.constantName))
            component.decoders.append(genDecoder(property.name, property.type, property.constantName, true))
            component.encoders.append(genEncoder(property.name, property.type, property.constantName))
        case .emptyArray:
            component.stringConstants.append(genStringConstant(property.constantName, property.key))
            component.initialisers.append(genInitializerForPrimitiveArray(property.name, "object", property.constantName))
            component.declarations.append(genVariableDeclaration(property.name, "Any", true))
            component.description.append(genDescriptionForPrimitiveArray(property.name, property.constantName))
            component.decoders.append(genDecoder(property.name, "Any", property.constantName, true))
            component.encoders.append(genEncoder(property.name, "Any", property.constantName))
        case .nullType:
            // Currently we do not deal with null values.
            break
        }
    }

    // MARK: - Customised methods for SWiftyJSON
    // MARK: - Initialisers
    func genInitializerForVariable(_ name: String, _ type: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        var variableType = type
        variableType.lowerCaseFirst()
        return "\(name) = json[\(constantName)].\(variableType)\(configuration.isOptional ? "" : "Value")"
    }

    func genInitializerForObject(_ name: String, _ type: String, _ constantName: String) -> String {
        return "\(name) = \(type)(json: json[\(constantName)])"
    }

    func genInitializerForObjectArray(_ name: String, _ type: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        if configuration.isOptional {
            return "if let items = json[\(constantName)].array { \(name) = items.map { \(type)(json: $0) } }"
        } else {
            return "\(name) = json[\(constantName)].arrayValue.map { \(type)(json: $0) }"
        }
    }

    func genInitializerForPrimitiveArray(_ name: String, _ type: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        var variableType = type
        variableType.lowerCaseFirst()
        if configuration.isOptional {
            if type == "object" {
                return "if let items = json[\(constantName)].array { \(name) = items.map { $0.\(variableType)} }"
            } else {
                return "if let items = json[\(constantName)].array { \(name) = items.map { $0.\(variableType)Value } }"
            }
        } else {
            return "\(name) = json[\(constantName)].arrayValue.map { $0.\(variableType)Value }"
        }
    }

    func genPrimitiveVariableDeclaration(_ name: String, _ type: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        let dim = configuration.isVariable ? "var" : "let"
        let optional = configuration.isOptional ? "?" : ""
        return "\(dim) \(name): \(type)\(optional)"
    }

    func genDescriptionForPrimitive(_ name: String, _ type: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        if configuration.isOptional {
            return "if let value = \(name) { dictionary[\(constantName)] = value }"
        } else {
            return "dictionary[\(constantName)] = \(name)"
        }
    }
    func genDescriptionForPrimitiveArray(_ name: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        if configuration.isOptional {
            return "if let value = \(name) { dictionary[\(constantName)] = value }"
        } else {
            return "dictionary[\(constantName)] = \(name)"
        }
    }

    func genDescriptionForObject(_ name: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        if configuration.isOptional {
            return "if let value = \(name) { dictionary[\(constantName)] = value.dictionaryRepresentation() }"
        } else {
            return "dictionary[\(constantName)] = \(name).dictionaryRepresentation()"
        }
    }

    func genDescriptionForObjectArray(_ name: String, _ constantName: String) -> String {
        guard let configuration = configuration else {
            return ""
        }
        if configuration.isOptional {
            return "if let value = \(name) { dictionary[\(constantName)] = value.map { $0.dictionaryRepresentation() } }"
        } else {
            return "dictionary[\(constantName)] = \(name).map { $0.dictionaryRepresentation() }"
        }
    }

    func genDecoder(_ name: String, _ type: String, _ constantName: String, _ isArray: Bool) -> String {
        guard let configuration = configuration else {
            return ""
        }
        let finalTypeName = isArray ? "[\(type)]" : type
        if configuration.isOptional {
            return "self.\(name) = aDecoder.decodeObject(forKey: \(constantName)) as? \(finalTypeName)"
        } else {
            return "self.\(name) = aDecoder.decodeObject(forKey: \(constantName)) as \(finalTypeName)"
        }
    }

}
