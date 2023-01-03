import openai

openai.api_key = "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" 
gpt3_model = openai.Model.get("text-davinci-002")

completion = openai.Completion.create( engine="text-davinci-002", 
             prompt="The quick brown fox jumped over the lazy dog.", 
             max_tokens=128, temperature=0.5, )
generated_text = completion.text 

