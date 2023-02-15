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
        answer = helpers.ask(ask_params[:question], $embedding)
        puts answer
        render json: { answer: answer }
    end
    def ask_params
        params.permit(:question)
    end
end
