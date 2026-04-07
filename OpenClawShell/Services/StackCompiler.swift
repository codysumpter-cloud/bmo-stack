import Foundation

final class StackCompiler {
    static func generateStack(from answers: QuestionnaireAnswerSet) -> UserStack {
        // Generate stack name based on primary goal and user type
        let stackName = "\(answers.primaryGoal.capitalized) Stack for \(answers.userType.capitalized)"
        
        // Determine primary assistant based on user type and goal
        let primaryAssistant = generatePrimaryAssistant(from: answers)
        
        // Generate supporting agents
        let supportingAgents = generateSupportingAgents(from: answers)
        
        // Generate workflows
        let workflows = generateWorkflows(from: answers)
        
        // Generate profiles
        let memoryProfile = generateMemoryProfile(from: answers)
        let permissionProfile = generatePermissionProfile(from: answers)
        let modelPreferenceProfile = generateModelPreferenceProfile(from: answers)
        
        return UserStack(
            name: stackName,
            primaryAssistant: primaryAssistant,
            supportingAgents: supportingAgents,
            workflows: workflows,
            memoryProfile: memoryProfile,
            permissionProfile: permissionProfile,
            modelPreferenceProfile: modelPreferenceProfile
        )
    }
    
    private static func generatePrimaryAssistant(from answers: QuestionnaireAnswerSet) -> AgentProfile {
        let role: String
        let description: String
        let capabilities: [String]
        let personalityTraits: [String]
        
        switch answers.userType.lowercased() {
        case "developer", "programmer", "engineer":
            role = "Development Assistant"
            description = "Helps with coding, debugging, and technical tasks"
            capabilities = ["code generation", "debugging assistance", "technical documentation", "api exploration"]
            personalityTraits = ["analytical", "precise", "patient"]
            
        case "researcher", "academic", "scientist":
            role = "Research Assistant"
            description = "Assists with literature review, data analysis, and knowledge synthesis"
            capabilities = ["literature search", "data interpretation", "hypothesis generation", "citation management"]
            personalityTraits = ["curious", "thorough", "skeptical"]
            
        case "manager", "lead", "executive":
            role = "Productivity Assistant"
            description = "Supports planning, communication, and decision-making"
            capabilities = ["meeting preparation", "task prioritization", "communication drafting", "progress tracking"]
            personalityTraits = ["organized", "proactive", "diplomatic"]
            
        default:
            role = "Personal Assistant"
            description = "Helps with daily tasks and information management"
            capabilities = ["task management", "information retrieval", "reminder setting", "basic automation"]
            personalityTraits = ["helpful", "adaptable", "friendly"]
        }
        
        // Adjust based on autonomy level
        if answers.autonomyLevel.lowercased().contains("autonomous") {
            capabilities.append("independent task execution")
            personalityTraits.append("proactive")
        }
        
        return AgentProfile(
            name: "\(role)",
            role: role,
            description: description,
            capabilities: capabilities,
            personalityTraits: personalityTraits
        )
    }
    
    private static func generateSupportingAgents(from answers: QuestionnaireAnswerSet) -> [AgentProfile> {
        var agents: [AgentProfile] = []
        
        // Always include a workflow orchestrator
        agents.append(AgentProfile(
            name: "Workflow Orchestrator",
            role: "Orchestrator",
            description: "Manages and coordinates complex workflows",
            capabilities: ["workflow planning", "task sequencing", "dependency management"],
            personalityTraits: ["organized", "systematic"]
        ))
        
        // Add specialist based on team shape
        if answers.teamShape.lowercased().contains("team") || answers.teamShape.lowercased().contains("collaborat") {
            agents.append(AgentProfile(
                name: "Collaboration Coordinator",
                role: "Collaborator",
                description: "Facilitates team communication and shared work",
                capabilities: ["meeting facilitation", "document sharing", "status updates", "conflict resolution"],
                personalityTraits: ["communicative", "empathetic", "diplomatic"]
            ))
        }
        
        // Add learning agent if optimization priority suggests growth
        if answers.optimizationPriority.lowercased().contains("quality") || 
           answers.optimizationPriority.lowercased().contains("versatil") {
            agents.append(AgentProfile(
                name: "Learning Companion",
                role: "Learner",
                description: "Helps you learn and adapt over time",
                capabilities: ["skill assessment", "learning path suggestion", "progress tracking", "knowledge retention"],
                personalityTraits: ["encouraging", "insightful", "adaptable"]
            ))
        }
        
        return agents
    }
    
    private static func generateWorkflows(from answers: QuestionnaireAnswerSet) -> [WorkflowProfile> {
        var workflows: [WorkflowProfile] = []
        
        // Basic daily workflow
        workflows.append(WorkflowProfile(
            name: "Daily Briefing",
            description: "Morning routine to prepare for the day",
            steps: ["Review calendar", "Check priorities", "Prepare resources"],
            triggers: ["morning", "start of day"],
            isEnabled: true
        ))
        
        // Goal-specific workflow
        if !answers.primaryGoal.isEmpty {
            workflows.append(WorkflowProfile(
                name: "\(answers.primaryGoal.capitalized) Progress",
                description: "Regular check-ins toward your primary goal",
                steps: ["Assess current progress", "Identify blockers", "Plan next steps"],
                triggers: ["daily", "weekly"],
                isEnabled: true
            ))
        }
        
        // Tool-focused workflow if tool posture is permissive
        if answers.toolPosture.lowercased().contains("permiss") || answers.toolPosture.lowercased().contains("integrat") {
            workflows.append(WorkflowProfile(
                name: "Tool Exploration",
                description: "Discover and evaluate new tools for your workflow",
                steps: ["Research tool options", "Test in sandbox", "Evaluate fit", "Document findings"],
                triggers: ["monthly", "on demand"],
                isEnabled: true
            ))
        }
        
        return workflows
    }
    
    private static func generateMemoryProfile(from answers: QuestionnaireAnswerSet) -> MemoryProfile {
        let persistenceLevel: MemoryProfile.PersistenceLevel
        let retentionPolicy: MemoryProfile.RetentionPolicy
        let storageLocation: MemoryProfile.StorageLocation
        let encryptionEnabled: Bool
        
        // Map memory posture to persistence level
        switch answers.memoryPosture.lowercased() {
        case let x where x.contains("transient"):
            persistenceLevel = .transient
        case let x where x.contains("session"):
            persistenceLevel = .session
        case let x where x.contains("permanent"):
            persistenceLevel = .permanent
        default:
            persistenceLevel = .persistent
        }
        
        // Map to retention policy
        switch answers.memoryPosture.lowercased() {
        case let x where x.contains("short"):
            retentionPolicy = .shortTerm
        case let x where x.contains("long") || x.contains("infinite"):
            retentionPolicy = .longTerm
        case let x where x.contains("medium"):
            retentionPolicy = .mediumTerm
        default:
            retentionPolicy = .mediumTerm
        }
        
        // Storage location - default to device only for privacy
        storageLocation = .deviceOnly
        
        // Encryption enabled by default for sensitive data
        encryptionEnabled = true
        
        return MemoryProfile(
            persistenceLevel: persistenceLevel,
            retentionPolicy: retentionPolicy,
            storageLocation: storageLocation,
            encryptionEnabled: encryptionEnabled
        )
    }
    
    private static func generatePermissionProfile(from answers: QuestionnaireAnswerSet) -> PermissionProfile {
        let fileSystemAccess: PermissionProfile.FileSystemAccess
        let networkAccess: PermissionProfile.NetworkAccess
        let deviceAccess: PermissionProfile.DeviceAccess
        var externalServices: [PermissionProfile.ExternalService] = []
        
        // Map tool posture to permissions
        switch answers.toolPosture.lowercased() {
        case let x where x.contains("restrict"):
            fileSystemAccess = .documentsOnly
            networkAccess = .localOnly
            deviceAccess = .none
        case let x where x.contains("balanc"):
            fileSystemAccess = .appSpecific
            networkAccess = .whitelisted
            deviceAccess = .none
        case let x where x.contains("permiss") || x.contains("integrat"):
            fileSystemAccess = .appSpecific
            networkAccess = .whitelisted
            deviceAccess = .none
            
            #if targetEnvironment(simulator)
            // In simulator, we can't access real hardware anyway
            #else
            // Enable basic device features for permissive posture
            if answers.toolPosture.lowercased().contains("device") {
                deviceAccess = .sensors
            } else {
                deviceAccess = .none
            }
            #endif
            
            #if targetEnvironment(simulator)
            #else
            #endif
        default:
            fileSystemAccess = .appSpecific
            networkAccess = .localOnly
            deviceAccess = .none
        }
        
        #if targetEnvironment(simulator)
        // Simulator doesn't have real hardware access
        #else
        // Add common external services based on user type
        if answers.userType.lowercased().contains("develop") {
            externalServices.append(PermissionProfile.ExternalService(
                name: "GitHub",
                serviceType: "version_control",
                isEnabled: true
            ))
        }
        
        if answers.userType.lowercased().contains("research") {
            externalServices.append(PermissionProfile.ExternalService(
                name: "ArXiv",
                serviceType: "academic",
                isEnabled: true
            ))
        }
        #endif
        
        return PermissionProfile(
            fileSystemAccess: fileSystemAccess,
            networkAccess: networkAccess,
            deviceAccess: deviceAccess,
            externalServices: externalServices
        )
    }
    
    private static func generateModelPreferenceProfile(from answers: QuestionnaireAnswerSet) -> ModelPreferenceProfile {
        let preferredBackend: ModelPreferenceProfile.PreferredBackend
        let quantizationPreference: ModelPreferenceProfile.QuantizationPreference
        let contextSizePreference: ModelPreferenceProfile.ContextSizePreference
        let performanceVsQuality: ModelPreferenceProfile.PerformanceVsQuality
        
        // Determine backend based on optimization priority
        switch answers.optimizationPriority.lowercased() {
        case let x where x.contains("speed") || x.contains("performance"):
            preferredBackend = .llamaCpp
            quantizationPreference = .int4
            performanceVsQuality = .performance
        case let x where x.contains("qualit"):
            preferredBackend = .mlc
            quantizationPreference = .fp16
            performanceVsQuality = .quality
        case let x where x.contains("cost") || x.contains("efficienc"):
            preferredBackend = .llamaCpp
            quantizationPreference = .int8
            performanceVsQuality = .balanced
        default:
            preferredBackend = .mlc
            quantizationPreference = .int4
            performanceVsQuality = .balanced
        }
        
        #if targetEnvironment(simulator)
        // Simulator doesn't have GPU acceleration, favor CPU-friendly options
        preferredBackend = .llamaCpp
        quantizationPreference = .int4
        #endif
        
        // Context size based on user type and task complexity
        switch answers.userType.lowercased() {
        case let x where x.contains("research") || x.contains("academic"):
            contextSizePreference = .large
        case let x where x.contains("execut") || x.contains("manag"):
            contextSizePreference = .medium
        default:
            contextSizePreference = .medium
        }
        
        // Adjust for optimization priority
        if answers.optimizationPriority.lowercased().contains("versatil") {
            contextSizePreference = .large
        }
        
        return ModelPreferenceProfile(
            preferredBackend: preferredBackend,
            quantizationPreference: quantizationPreference,
            contextSizePreference: contextSizePreference,
            performanceVsQuality: performanceVsQuality
        )
    }
}