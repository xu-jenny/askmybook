class Question < ApplicationRecord
    validates :question, presence: true
    validates :answer, presence: true
    def self.process_question(question)
        if question[-1] != '?'
            question += '?'
        end
        return question.downcase.strip.squish.tr('"', "'")
    end
    def self.create_question(question, answer, question_embedding, similiarq="")
        Question.create({ question: question, answer: answer, embedding: question_embedding, similiarq: similiarq })
    end
end
