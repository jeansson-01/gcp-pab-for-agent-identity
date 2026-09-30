"""ADK Agent definition with Google Cloud Storage MCP Toolset."""
import os
import sys
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

AGENT_INSTRUCTION = """
You are the Cloud Storage Security Inspector Agent deployed in Google Cloud Agent Runtime.
Your primary role is to inspect Google Cloud Storage (GCS) buckets and list their objects using the Google Cloud Storage MCP tools.

Guidelines:
1. When asked to inspect or list objects in a bucket (e.g. 'gs://bucket-name' or 'bucket-name'), call the MCP tool 'list_objects'.
2. If access succeeds, summarize the objects found clearly, including file names and approximate sizes if available.
3. If access fails (e.g. 403 Forbidden, Principal Access Boundary violation, or Permission Denied), report the exact error message clearly and state that access was denied by security policy enforcement.
4. Do not speculate or invent file names if the tool call fails.
"""

# Configure Stdio MCP connection to the official GCP Storage MCP server
# Node.js and @google-cloud/storage-mcp are installed in the container environment
storage_mcp_toolset = McpToolset(
    connection_params=StdioConnectionParams(
        server_params=StdioServerParameters(
            command="npx",
            args=["-y", "@google-cloud/storage-mcp"],
            env={
                "PATH": os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin"),
                "HOME": os.environ.get("HOME", "/root"),
            },
        )
    ),
    tool_filter=["list_objects", "list_buckets", "get_object_metadata"],
)

root_agent = Agent(
    name="pab_storage_inspector",
    model="gemini-2.5-flash",
    instruction=AGENT_INSTRUCTION,
    tools=[storage_mcp_toolset],
)
