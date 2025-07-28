import { OpenAI } from "openai";
import { NextResponse } from "next/server";
import {
  SYSTEM_PROMPT,
  generateQuestionsPrompt,
} from "@/lib/prompts/generate-questions";
import { logger } from "@/lib/logger";

export const maxDuration = 60;

export async function POST(req: Request, res: Response) {
  logger.info("generate-interview-questions request received");
  
  try {
    // Parse request body with error handling
    let body;
    try {
      body = await req.json();
      logger.info("Request body parsed successfully", JSON.stringify(body));
    } catch (parseError) {
      logger.error("Failed to parse request body", JSON.stringify({
        error: parseError instanceof Error ? parseError.message : String(parseError)
      }));
      
      return NextResponse.json(
        { error: "Invalid JSON in request body" },
        { status: 400 }
      );
    }
    
    // Validate required fields
    const requiredFields = ['name', 'objective', 'number', 'context'];
    const missingFields = requiredFields.filter(field => body[field] === undefined || body[field] === null);
    
    if (missingFields.length > 0) {
      logger.error("Missing required fields", JSON.stringify(missingFields));
      
      return NextResponse.json(
        { error: `Missing required fields: ${missingFields.join(', ')}` },
        { status: 400 }
      );
    }

    logger.info("Request validation passed");
    
    // Check OpenAI API key
    if (!process.env.OPENAI_API_KEY) {
      logger.error("OpenAI API key not found in environment variables");
      
      return NextResponse.json(
        { error: "OpenAI API key not configured" },
        { status: 500 }
      );
    }
    
    logger.info("OpenAI API key found, initializing client");
    
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
      baseURL: process.env.OPENAI_BASE_URL,
      maxRetries: 5,
      dangerouslyAllowBrowser: true,
    });
    
    logger.info("OpenAI client initialized successfully");

    const userPrompt = generateQuestionsPrompt(body);
    logger.info("Generated user prompt", JSON.stringify({ 
      promptLength: userPrompt.length,
      bodyFields: Object.keys(body)
    }));
    
    logger.info("Making OpenAI API call", JSON.stringify({
      model: process.env.OPENAI_MODEL || "deepseek-chat",
      systemPromptLength: SYSTEM_PROMPT.length,
      userPromptLength: userPrompt.length,
      baseURL: process.env.OPENAI_BASE_URL
    }));

    const baseCompletion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || "deepseek-chat",
      messages: [
        {
          role: "system",
          content: SYSTEM_PROMPT,
        },
        {
          role: "user",
          content: userPrompt,
        },
      ],
      response_format: { type: "json_object" },
    });
    
    logger.info("OpenAI API call completed successfully", JSON.stringify({
      usage: baseCompletion.usage,
      choicesCount: baseCompletion.choices?.length || 0
    }));

    const basePromptOutput = baseCompletion.choices[0] || {};
    const content = basePromptOutput.message?.content;
    
    if (!content) {
      logger.error("No content received from OpenAI API");
      
      return NextResponse.json(
        { error: "No content generated" },
        { status: 500 }
      );
    }

    logger.info("Interview questions generated successfully", JSON.stringify({
      contentLength: content.length,
      finishReason: basePromptOutput.finish_reason
    }));
    
    // Try to parse the JSON to validate it
    try {
      const parsedContent = JSON.parse(content);
      logger.info("Generated content JSON is valid", JSON.stringify({
        hasQuestions: !!parsedContent.questions,
        questionsCount: parsedContent.questions?.length || 0,
        hasDescription: !!parsedContent.description
      }));
    } catch (parseError) {
      logger.error("Generated content is not valid JSON", JSON.stringify({
        error: parseError instanceof Error ? parseError.message : String(parseError),
        contentPreview: content.substring(0, 200)
      }));
    }

    return NextResponse.json(
      {
        response: content,
      },
      { status: 200 },
    );
  } catch (error) {
    logger.error("Error generating interview questions", JSON.stringify({
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      name: error instanceof Error ? error.name : undefined
    }));

    return NextResponse.json(
      { error: "internal server error" },
      { status: 500 },
    );
  }
}
