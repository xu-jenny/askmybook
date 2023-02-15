import React, { useState } from "react";

export default () => {
  const [question, setQuestion] = React.useState("")
  const [answer, setAnswer] = React.useState(null)
  const [loading, setLoading] = React.useState(false)

  React.useEffect(() => {
    fetch('/home/load', {
      method: 'GET',
    })
  }, [])

  const token = document.querySelector('meta[name="csrf-token"]').content
  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoading(true)
    let body = JSON.stringify({ question })
    const response = await fetch('/home/ask', {
      method: 'POST',
      body: body,
      headers: {
        "X-CSRF-Token": token,
        'Content-Type': 'application/json'
      },
    })
    console.log(response.body)
    const data = await response.json()
    console.log(data)
    setAnswer(data.answer)
    setLoading(false)
  }

  return (
    <>
      <h1>Home</h1>
      <form onSubmit={handleSubmit}>
        <label>Enter your question:
          <input
            type="text"
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
          />
        </label>
        <input type="submit" />
      </form>
      {loading ? <p>Loading...</p> : <p>{answer}</p>}
    </>
  )
}
