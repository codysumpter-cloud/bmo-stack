import Foundation

struct UserStack: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var primaryAssistant: AgentProfile
    var supportingAgents: [AgentProfile]
    var workflows: [WorkflowProfile]
    var memoryProfile: MemoryProfile
    var permissionProfile: PermissionProfile
    var modelPreferenceProfile: ModelPreferenceProfile
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        primaryAssistant: AgentProfile,
        supportingAgents: [AgentProfile] = [],
        workflows: [WorkflowProfile] = [],
        memoryProfile: MemoryProfile,
        permissionProfile: PermissionProfile,
        modelPreferenceProfile: ModelPreferenceProfile,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.primaryAssistant = primaryAssistant
        self.supportingAgents = supportingAgents
        self.workflows = workflows
        self.memoryProfile = memoryProfile
        self.permissionProfile = permissionProfile
        self.modelPreferenceProfile = modelPreferenceProfile
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct AgentProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: String
    var description: String
    var capabilities: [String]
    var personalityTraits: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        role: String,
        description: String,
        capabilities: [String] = [],
        personalityTraits: [String] = []
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.description = description
        self.capabilities = capabilities
        self.personalityTraits = personalityTraits
    }
}

struct WorkflowProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var steps: [String]
    var triggers: [String]
    var isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        steps: [String] = [],
        triggers: [String] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.triggers = triggers
        self.isEnabled = isEnabled
    }
}

struct MemoryProfile: Codable, Hashable {
    var persistenceLevel: PersistenceLevel
    var retentionPolicy: RetentionPolicy
    var storageLocation: StorageLocation
    var encryptionEnabled: Bool
    
    enum PersistenceLevel: String, Codable {
        case transient
        case session
        case persistent
        case permanent
    }
    
    enum RetentionPolicy: String, Codable {
        case none
        case shortTerm
        case mediumTerm
        case longTerm
        case infinite
    }
    
    enum StorageLocation: String, Codable {
        case deviceOnly
        case deviceAndBackup
        case deviceAndCloud
        case encryptedVault
    }
    
    init(
        persistenceLevel: PersistenceLevel = .persistent,
        retentionPolicy: RetentionPolicy = .mediumTerm,
        storageLocation: StorageLocation = .deviceOnly,
        encryptionEnabled: Bool = true
    ) {
        self.persistenceLevel = persistenceLevel
        self.retentionPolicy = retentionPolicy
        self.storageLocation = storageLocation
        self.encryptionEnabled = encryptionEnabled
    }
}

struct PermissionProfile: Codable, Hashable {
    var fileSystemAccess: FileSystemAccess
    var networkAccess: NetworkAccess
    var deviceAccess: DeviceAccess
    var externalServices: [ExternalService]
    
    enum FileSystemAccess: String, Codable {
        case none
        case documentsOnly
        case appSpecific
        case fullAccess
    }
    
    enum NetworkAccess: String, Codable {
        case none
        case localOnly
        case whitelisted
        case unrestricted
    }
    
    enum DeviceAccess: String, Codable {
        case none
        case camera
        case microphone
        case location
        case sensors
        case all
    }
    
    struct ExternalService: Identifiable, Codable, Hashable {
        let id: UUID
        var name: String
        var serviceType: String
        var isEnabled: Bool
        
        init(
            id: UUID = UUID(),
            name: String,
            serviceType: String,
            isEnabled: Bool = false
        ) {
            self.id = id
            self.name = name
            self.serviceType = serviceType
            self.isEnabled = isEnabled
        }
    }
    
    init(
        fileSystemAccess: FileSystemAccess = .appSpecific,
        networkAccess: NetworkAccess = .localOnly,
        deviceAccess: DeviceAccess = .none,
        externalServices: [ExternalService] = []
    ) {
        self.fileSystemAccess = fileSystemAccess
        self.networkAccess = networkAccess
        self.deviceAccess = deviceAccess
        self.externalServices = externalServices
    }
}

struct ModelPreferenceProfile: Codable, Hashable {
    var preferredBackend: PreferredBackend
    var quantizationPreference: QuantizationPreference
    var contextSizePreference: ContextSizePreference
    var performanceVsQuality: PerformanceVsQuality
    
    enum PreferredBackend: String, Codable {
        case mlc
        case llamaCpp
        case huggingFace
        case custom
    }
    
    enum QuantizationPreference: String, Codable {
        case fp16
        case int8
        case int4
        case mixed
    }
    
    enum ContextSizePreference: String, Codable {
        case small
        case medium
        case large
        case extraLarge
    }
    
    enum PerformanceVsQuality: String, Codable {
        case performance
        case balanced
        case quality
    }
    
    init(
        preferredBackend: PreferredBackend = .mlc,
        quantizationPreference: QuantizationPreference = .int4,
        contextSizePreference: ContextSizePreference = .medium,
        performanceVsQuality: PerformanceVsQuality = .balanced
    ) {
        self.preferredBackend = preferredBackend
        self.quantizationPreference = quantizationPreference
        self.contextSizePreference = contextSizePreference
        self.performanceVsQuality = performanceVsQuality
    }
}

struct QuestionnaireAnswerSet: Codable, Hashable {
    var primaryGoal: String
    var userType: String
    var teamShape: String
    var autonomyLevel: String
    var memoryPosture: String
    var toolPosture: String
    var optimizationPriority: String
    
    init(
        primaryGoal: String = "",
        userType: String = "",
        teamShape: String = "",
        autonomyLevel: String = "",
        memoryPosture: String = "",
        toolPosture: String = "",
        optimizationPriority: String = ""
    ) {
        self.primaryGoal = primaryGoal
        self.userType = userType
        self.teamShape = teamShape
        self.autonomyLevel = autonomyLevel
        self.memoryPosture = memoryPosture
        self.toolPosture = toolPosture
        self.optimizationPriority = optimizationPriority
    }
}