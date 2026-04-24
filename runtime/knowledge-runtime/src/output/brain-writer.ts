import { SlugRegistry } from './slug-registry';

export interface WriteRequest {
  title: string;
  content: string;
  evidence: string[];
  metadata: Record<string, any>;
  desiredSlug?: string;
}

export interface WriteResult {
  slug: string;
  status: 'created' | 'merged' | 'failed';
  conflictResolved: boolean;
}

export class BrainWriter {
  constructor(
    private registry: SlugRegistry,
    private storageEngine: any // Abstract storage engine for pages/nodes
  ) {}

  async write(request: WriteRequest): Promise<WriteResult> {
    // 1. Anti-Hallucination Check: Verify content against evidence
    const isVerified = await this.verifyAgainstEvidence(request.content, request.evidence);
    if (!isVerified) {
      throw new Error('Content verification failed: BrainWriter detected potential hallucination.');
    }

    // 2. Slug Resolution
    const slugTarget = request.desiredSlug || request.title.toLowerCase().replace(/\s+/g, '-');
    const slugResult = await this.registry.create(slugTarget, request.title, 'page');

    // 3. Deterministic Persistence
    try {
      await this.storageEngine.savePage({
        slug: slugResult.slug,
        title: request.title,
        content: request.content,
        ...request.metadata
      });

      return {
        slug: slugResult.slug,
        status: slugResult.isConflict ? 'merged' : 'created',
        conflictResolved: slugResult.isConflict
      };
    } catch (e) {
      console.error('Persistence failure in BrainWriter:', e);
      return { slug: slugResult.slug, status: 'failed', conflictResolved: false };
    }
  }

  private async verifyAgainstEvidence(content: string, evidence: string[]): Promise<boolean> {
    if (evidence.length === 0) return false;
    
    // Simplistic deterministic check: Ensure key terms from evidence appear in content
    // In a production system, this would use an LLM as a 'judge' or a cross-reference matrix
    const evidenceKeywords = evidence.flatMap(e => e.split(/\s+/)).filter(w => w.length > 5);
    const matchCount = evidenceKeywords.filter(w => content.includes(w)).length;
    
    return matchCount > 0; // Baseline requirement
  }
}
