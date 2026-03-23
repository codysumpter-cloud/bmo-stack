/**
 * Diagnostic Consultation Service for BMO-stack
 * Provides pump specialist guidance to enhance FLOWCOMMANDER diagnostic workflows
 */

const { Prismo } = require('../council/PRISMO');
const { BMO } = require('../council/BMO_TRON');
const { PumpSpecialist } = require('../council/diagnostic/PUMP_SPECIALIST');

class DiagnosticConsultationService {
  constructor() {
    this.prismo = new Prismo();
    this.bmo = new BMO();
    this.pumpSpecialist = new PumpSpecialist();
  }

  /**
   * Consult with pump specialist for diagnostic enhancement
   * @param {Object} context - Diagnostic context from FLOWCOMMANDER
   * @returns {Promise<Object>} Enhancement recommendations
   */
  async consult(context) {
    try {
      // Extract key information
      const { symptom, responses, siteContext, technicianContext } = context;
      
      // Build consultation prompt for pump specialist
      const prompt = this.buildConsultationPrompt(symptom, responses, siteContext, technicianContext);
      
      // Get council recommendation (Prismo orchestrates)
      const councilRecommendation = await this.prismo.delegate({
        task: 'diagnostic_enhancement',
        prompt,
        agents: ['PUMP_SPECIALIST'],
        context
      });
      
      // Have BMO format the final response
      const formattedResponse = await this.bmo.process({
        rawInput: councilRecommendation,
        context: { source: 'diagnostic_consultation' }
      });
      
      // Parse and structure the response
      return this.parseResponse(formattedResponse);
    } catch (error) {
      console.error('Diagnostic consultation failed:', error);
      // Return fallback enhancement
      return this.getFallbackEnhancement(symptom);
    }
  }

  /**
   * Build consultation prompt for pump specialist
   */
  buildConsultationPrompt(symptom, responses, siteContext, technicianContext) {
    return `
PUMP SPECIALIST CONSULTATION REQUEST

SYMPTOM: ${symptom}

CURRENT DIAGNOSTIC RESPONSES:
${responses.map((r, i) => `${i+1}. ${r.prompt}: ${r.responseValue}${r.notes ? ' (Notes: ' + r.notes + ')' : ''}`).join('\n')}

SITE CONTEXT:
- Station ID: ${siteContext.stationId || 'unknown'}
- System Type: ${siteContext.systemType || 'unknown'}
- Controller Type: ${siteContext.controllerType || 'unknown'}
- OEM: ${siteContext.oem || 'unknown'}
- Pump Count: ${siteContext.pumpCount || 'unknown'}
- Recent Alerts: ${siteContext.recentAlerts || 'none'}
- Configuration Summary: ${siteContext.configurationSummary || 'not available'}

TECHNICIAN CONTEXT:
- Skill Level: ${technicianContext.skillLevel || 'unknown'}
- Certifications: ${technicianContext.certifications || 'none'}
- Experience Years: ${technicianContext.experienceYears || 'unknown'}

ENVIRONMENTAL FACTORS:
- Weather: ${siteContext.weather || 'not provided'}
- Demand Pattern: ${siteContext.demandPattern || 'not provided'}
- Time of Day: ${siteContext.timeOfDay || 'not provided'}

REQUEST:
Please provide pump-specific diagnostic enhancement including:
1. UPDATED PROBABLE CAUSES - Ranked by likelihood with confidence indicators
2. SPECIFIC NEXT CHECKS - Targeted measurements or inspections to perform
3. PARTS TO CONSIDER - Specific parts to bring based on symptoms and history
4. ESCALATION CRITERIA - Clear indicators when to escalate
5. CONTEXTUAL CLOSE-OUT NOTE - Suggested note for service record
6. ALTERNATIVE DIAGNOSTIC PATHS - If current approach isn't resolving

Consider pump affinity laws, common failure modes, tuning effects, and safety procedures.
Format response as actionable, field-ready guidance.
`;
  }

  /**
   * Parse council/BMO response into structured enhancement
   */
  parseResponse(response) {
    // In a real implementation, this would parse the structured response
    // For MVP, return a structured enhancement based on common patterns
    
    return {
      probableCauses: this.extractProbableCauses(response),
      nextChecks: this.extractNextChecks(response),
      partsToConsider: this.extractPartsToConsider(response),
      escalationCriteria: this.extractEscalationCriteria(response),
      closeOutNote: this.extractCloseOutNote(response),
      alternativePaths: this.extractAlternativePaths(response),
      confidence: 'medium', // Would be calculated based on data quality
      timestamp: new Date().toISOString()
    };
  }

  // Helper methods to extract specific sections from response
  extractProbableCauses(response) {
    // Simplified extraction - would be more sophisticated in reality
    return [
      { cause: 'Demand increase', confidence: 'high' },
      { cause: 'Tuning issue', confidence: 'medium' },
      { cause: 'Mechanical restriction', confidence: 'medium' }
    ];
  }

  extractNextChecks(response) {
    return [
      'Verify actual discharge pressure with calibrated gauge',
      'Check pump frequency vs setpoint band',
      'Inspect for temporary vs persistent demand spike',
      'Review alarm history for related events'
    ];
  }

  extractPartsToConsider(response) {
    return [
      { part: 'Pressure gauge (calibrated)', reason: 'Verification measurement' },
      { part: 'Suction strainer', reason: 'Common restriction point' },
      { part: 'Impeller wear ring', reason: 'Wear-related performance loss' }
    ];
  }

  extractEscalationCriteria(response) {
    return [
      'Pressure remains >15% below setpoint after checks',
      'Mechanical binding or restriction found',
      'Electrical faults detected (voltage imbalance, phase loss)',
      'Safety concerns identified (lockout/tagout required)'
    ];
  }

  extractCloseOutNote(response) {
    return 'Diagnostic enhanced with pump specialist guidance. Verified pressure measurements and demand patterns before determining root cause.';
  }

  extractAlternativePaths(response) {
    return [
      'If pressure normal but flow low: check for suction-side restrictions',
      'If pressure oscillates: review PID tuning and sensor placement',
      'If electrical checks normal: proceed with mechanical inspection'
    ];
  }

  getFallbackEnhancement(symptom) {
    // Return basic enhancement if consultation fails
    return {
      probableCauses: [{ cause: 'Requires further investigation', confidence: 'low' }],
      nextChecks: ['Verify measurements with calibrated equipment', 'Review service history'],
      partsToConsider: [],
      escalationCriteria: ['Unable to verify measurements safely'],
      closeOutNote: 'Basic diagnostic completed. Recommend escalation for specialist review.',
      alternativePaths: ['Consider manufacturer-specific diagnostic procedures'],
      confidence: 'low',
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = DiagnosticConsultationService;