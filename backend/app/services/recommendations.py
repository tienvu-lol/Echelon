"""Recommendation pipeline.

This module will coordinate between Gemini (embeddings, explanations)
and Databricks (AI Search, metadata filtering) to produce personalized
opportunity recommendations.

Not implemented in the skeleton — will be built as a separate task.

Intended pipeline:
1. Receive student profile
2. Generate embedding from profile_text using Gemini
3. Query Databricks AI Search with the embedding vector
4. Apply metadata filters (class year, major, deadline, type)
5. Pass finalist opportunities to Gemini for personalized explanations
6. Return ranked, explained opportunity cards
"""
