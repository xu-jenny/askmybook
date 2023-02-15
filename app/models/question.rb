class Question < ApplicationRecord
    validates :question, presence: true
    validates :answer, presence: true
    def self.process_question(question)
        if question[-1] != '?'
            question += '?'
        end
        return question.downcase.strip.squish.tr('"', "'")
    end
    def self.get(question)
        return Question.find_by question: question
    end
    def self.create_question(question, answer, question_embedding, similiarq="")
        Question.create({ question: question, answer: answer, embedding: question_embedding, similiarq: similiarq })
    end
    def self.find_similiarq(question)
        q = Question.where("similiarq LIKE ?", "%"+question+"%")
        if q.any?
            return q[0]
        end
        return nil
    end
    def self.update_similiarq(new_q, key)
        # key is answer column
        q = Question.find_by answer: key
        q.similiarq << new_q
        q.save
    end
end
