class HomeController < ApplicationController
    def load
        filepath = './embeddings.csv'
        if !File.file?(filepath) 
            AwsClient.download_object(filepath, "minimalist_entrepreneur_embedding.csv")
        end
        $embedding = helpers.load_embedding_csv(filepath)
    end
    def ask
        @question = Question.process_question(ask_params[:question])
        q = helpers.find_existing_question(@question)
        if q != nil
            # it's possible the occurance includes the time user just asked, if Question.increment_count call finishes before this return. there's no way to know for sure which will finish first.
            # I decided it was okay to upcount by 1 the count accuracy is not as important as code simplicty and performance of using threads.
            return render json: { answer: q.answer, occurance: q.occurance }    
        end
        
        @question_embedding = OpenaiClient.get_embedding(@question)     # this call normall takes around 1000ms
        answer = helpers.find_similiar_question(@question_embedding)
        if answer != nil
            Thread.start {
                Question.update_similiarq(@question, answer)
            }
            q = Question.find_by answer: answer
            return render json: { answer: answer, occurance: q.occurance }
        end

        answer = helpers.ask(@question, $embedding, @question_embedding)    # this call takes about 4000ms
        Thread.start {
            Question.create_question(@question, answer, @question_embedding)
            CacheClient.write_question(@question, answer)
        }
        return render json: { answer: answer }
    end
    def ask_params
        params.permit(:question)
    end
end
