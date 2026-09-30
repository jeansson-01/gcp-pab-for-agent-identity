"""FastAPI container serving entrypoint for Agent Runtime."""
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from agent import root_agent

app = FastAPI(title="PAB Storage Inspector Agent", version="1.0.0")

class QueryRequest(BaseModel):
    prompt: str
    user_id: str = "demo-user"

class QueryResponse(BaseModel):
    response: str
    agent_name: str

@app.get("/healthz")
def health_check():
    return {"status": "healthy", "agent": root_agent.name}

@app.post("/query", response_model=QueryResponse)
async def query_agent(request: QueryRequest):
    try:
        # In Agent Runtime, queries are dispatched to the root_agent
        result = await root_agent.run(request.prompt)
        return QueryResponse(response=str(result), agent_name=root_agent.name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
