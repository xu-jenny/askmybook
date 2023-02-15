class HomeController < ApplicationController
    def load
        filepath = './embeddings.csv'
        p "embedding file exists?", File.file?(filepath)
        if File.file?(filepath)
            $embedding = helpers.load_embedding_csv(filepath)
        else 
            $embedding = helpers.download_object(filepath, "minimalist_entrepreneur_embedding.csv")
        end
        p "Finish loading embedding", $embedding.length()
    end
    def ask
        @question = Question.process_question(ask_params[:question])
        @question_embedding = helpers.get_embedding(@question)
        answer = helpers.ask(ask_params[:question], $embedding)
        Question.create_question(@question, answer, @question_embedding)
        render json: { answer: answer }
    end
    def ask_params
        params.permit(:question)
    end
end
