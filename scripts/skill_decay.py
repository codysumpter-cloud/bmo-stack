import json

class Skill:
    def __init__(self, name, level, last_used):
        self.name = name
        self.level = level
        self.last_used = last_used

    def is_unused(self, threshold):
        return self.last_used < threshold

class SkillDecay:
    def __init__(self, skills):
        self.skills = skills

    def prune_unused_skills(self, threshold):
        self.skills = [skill for skill in self.skills if not skill.is_unused(threshold)]

    def save_skills(self, filename):
        with open(filename, 'w') as f:
            json.dump([skill.__dict__ for skill in self.skills], f)

    @classmethod
    def load_skills(cls, filename):
        with open(filename, 'r') as f:
            skills_data = json.load(f)
            skills = [Skill(**data) for data in skills_data]
            return cls(skills)

# Usage Example
skills = [
    Skill('Python', 5, '2026-02-01'),
    Skill('JavaScript', 4, '2026-01-15'),
    Skill('C#', 3, '2025-12-20'),
]

skill_decay = SkillDecay(skills)
threshold_date = '2026-03-01'  # Define a threshold date
skill_decay.prune_unused_skills(threshold_date)
skill_decay.save_skills('skills.json')