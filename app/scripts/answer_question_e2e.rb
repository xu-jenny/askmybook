require 'pdf-reader'
require "ruby/openai"
require 'csv'

$client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_KEY'])

def get_embedding(text, model)
    $client.embeddings(
        parameters: {
            model: model,
            input: text
        }
    )
end

def print_embedding(embedding)
    embedding.each do |page|
        puts "page #{page[0]} tokens: #{page[2]} len_embed: #{page[1].length()}"
    end
end

def compute_doc_embedding_by_page(reader, embedding, start, last)
    reader.pages[start..last].each_with_index do |page, index|
        if(page.text.length() > 0)
            content = page.text.split.join(" ")
            result = get_embedding(page.text, "text-embedding-ada-002")    # get_embedding returns number of tokens
            if result.key?("data")
                puts "index+start:#{index+start}, #{content[0,10]}, #{result["data"][0]["embedding"].length()}"
                embedding << [index+start, result["data"][0]["embedding"], result['usage']['total_tokens'], content]
            end
        end
    end
    return embedding
end

def compute_doc_embedding(book_filename, csv_filename)
    CSV.open(csv_filename, 'a') do |csv|
        reader = PDF::Reader.new(book_filename)
        start_index = 5
        while start_index < reader.pages.length() do
            embedding = Array.new()
            compute_doc_embedding_by_page(reader, embedding, start_index, start_index+29)
            start_index += 30
            sleep 300   # sleeping to account for API limits
        end
    end
end

compute_doc_embedding("book.pdf", "embeddings.csv")

