module HomeHelper

    def load_embedding_csv(filepath)
        embedding = CSV.read(filepath)
        hash = Hash.new()
        embedding.each do |page|
            hash[page[0]] = [page[1].gsub("[", "").gsub("]", "").split(/\s*,\s*/).map(&:to_f), page[2], page[3]]
        end
        return hash
    end

     ### FIND DUPLICATE QUESTION FUNCTIONS ###

     def find_existing_question(question)
        # check if question exist in cache
        q = CacheClient.get_question(@question)
        if q != nil
            return q
        end

        # check if question string exist in db
        q = Question.get(question)
        if q != nil
            return q.answer
        end

        # check for similiar questions
        q = Question.find_similiarq(question)
        if q != nil
            return q.answer
        end
        return nil
    end

    def find_similiar_question(question_embedding)
        answers = []
        Question.pluck(:embedding, :answer).each do |e|
            if e[0].length() > 0
                sim = AskQuestionUtil.vector_similarity(e[0].map(&:to_f), question_embedding)
                p sim, e[1]
                if sim > 0.95
                    answers << [sim, e[1]]
                end
            end
        end
        if answers.length() > 0
            p "similiar q found!",answers.sort_by{|x,y|x}[0][1]
            return answers.sort_by{|x,y|x}[0][1]
        end
        return nil
    end

    ### ASK QUESTION ###

    def ask(question, embedding, question_embedding=nil)
        if question_embedding == nil
            question_embedding = OpenaiClient.get_embedding(question)
        end
        prompt = AskQuestionUtil.construct_promopt(question, embedding, question_embedding)
        answer = OpenaiClient.get_completion(prompt)
        return answer["choices"][0]["text"]
    end

end
