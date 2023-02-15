class HomeController < ApplicationController
    def load
        filepath = './embeddings.csv'
        p "embedding file exists?", File.file?(filepath)
        if File.file?(filepath)
            $embedding = helpers.load_embedding_csv(filepath)
        else 
            $embedding = AwsClient.download_object(filepath, "minimalist_entrepreneur_embedding.csv")
        end
        p "Finish loading embedding", $embedding.length()
    end
    def ask
        @question = Question.process_question(ask_params[:question])
        answer = helpers.find_existing_question(@question)
        if answer != nil
            return render json: { answer: answer }
        end
        
        @question_embedding = OpenaiClient.get_embedding(@question) 
        answer = helpers.find_similiar_question(@question_embedding)
        if answer != nil
            Question.update_similiarq(@question, answer)
            return render json: { answer: answer }
        end

        answer = helpers.ask(@question, $embedding, @question_embedding)
        Question.create_question(@question, answer, @question_embedding)
        return render json: { answer: answer }
    end
    def ask_params
        params.permit(:question)
    end
end
