import numpy as np

class SkillConfidence:
    def __init__(self, thresholds):
        self.thresholds = thresholds

    def evaluate(self, skill_scores):
        results = {}
        for skill, score in skill_scores.items():
            if skill in self.thresholds:
                if score >= self.thresholds[skill]:
                    results[skill] = 'PASS'
                else:
                    results[skill] = 'FAIL'
            else:
                results[skill] = 'UNKNOWN'
        return results

# Example usage:
if __name__ == '__main__':
    thresholds = {'python': 0.75, 'machine_learning': 0.80}
    skill_confidence = SkillConfidence(thresholds)
    scores = {'python': 0.85, 'machine_learning': 0.70, 'data_analysis': 0.90}
    print(skill_confidence.evaluate(scores))
