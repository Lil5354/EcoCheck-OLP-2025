/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - AI Image Analyzer Service
 * Uses Hugging Face Inference API to analyze waste images
 */

const axios = require("axios");

const HUGGINGFACE_API_URL = "https://api-inference.huggingface.co/models";
const HUGGINGFACE_TOKEN = process.env.HUGGINGFACE_API_TOKEN;

// Model for image classification - using a general vision model
// We'll use Vision Transformer (ViT) for image understanding
const IMAGE_CLASSIFICATION_MODEL = "google/vit-base-patch16-224";

/**
 * Download image from URL and convert to base64
 */
async function downloadImageAsBase64(imageUrl) {
  try {
    const response = await axios.get(imageUrl, {
      responseType: "arraybuffer",
      timeout: 10000,
    });

    const base64 = Buffer.from(response.data).toString("base64");
    const mimeType = response.headers["content-type"] || "image/jpeg";
    
    return {
      base64,
      mimeType,
    };
  } catch (error) {
    console.error("[AI] Error downloading image:", error.message);
    throw new Error(`Failed to download image: ${error.message}`);
  }
}

/**
 * Analyze image using Hugging Face Vision Transformer
 * This will classify the image and extract features
 */
async function analyzeImageWithViT(imageBase64, mimeType) {
  try {
    if (!HUGGINGFACE_TOKEN) {
      throw new Error("HUGGINGFACE_API_TOKEN is not set");
    }

    const imageData = `data:${mimeType};base64,${imageBase64}`;

    const response = await axios.post(
      `${HUGGINGFACE_API_URL}/${IMAGE_CLASSIFICATION_MODEL}`,
      {
        inputs: imageData,
      },
      {
        headers: {
          Authorization: `Bearer ${HUGGINGFACE_TOKEN}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    return response.data;
  } catch (error) {
    console.error("[AI] Error analyzing with ViT:", error.message);
    throw new Error(`AI analysis failed: ${error.message}`);
  }
}

/**
 * Use a more specific model for object detection if available
 * Falls back to ViT classification
 */
async function detectObjectsInImage(imageBase64, mimeType) {
  try {
    if (!HUGGINGFACE_TOKEN) {
      throw new Error("HUGGINGFACE_API_TOKEN is not set");
    }

    // Try using DETR (Detection Transformer) for object detection
    const DETR_MODEL = "facebook/detr-resnet-50";
    const imageData = `data:${mimeType};base64,${imageBase64}`;

    const response = await axios.post(
      `${HUGGINGFACE_API_URL}/${DETR_MODEL}`,
      {
        inputs: imageData,
      },
      {
        headers: {
          Authorization: `Bearer ${HUGGINGFACE_TOKEN}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    return response.data;
  } catch (error) {
    console.warn("[AI] DETR detection failed, falling back to ViT:", error.message);
    // Fallback to ViT
    return analyzeImageWithViT(imageBase64, mimeType);
  }
}

/**
 * Extract waste type from AI analysis results
 * Maps AI classification to our waste types: household, recyclable, bulky, organic, hazardous
 */
function extractWasteType(aiResults) {
  // Convert results to lowercase string for matching
  const resultsStr = JSON.stringify(aiResults).toLowerCase();

  // Keywords for different waste types
  const wasteTypeKeywords = {
    recyclable: [
      "plastic",
      "bottle",
      "can",
      "metal",
      "aluminum",
      "paper",
      "cardboard",
      "glass",
      "recyclable",
      "recycle",
    ],
    bulky: [
      "furniture",
      "appliance",
      "large",
      "bulky",
      "mattress",
      "sofa",
      "refrigerator",
      "washing machine",
    ],
    organic: [
      "food",
      "organic",
      "vegetable",
      "fruit",
      "compost",
      "biodegradable",
      "kitchen waste",
    ],
    hazardous: [
      "battery",
      "chemical",
      "hazardous",
      "toxic",
      "medicine",
      "electronic",
      "e-waste",
    ],
    household: [
      "trash",
      "garbage",
      "waste",
      "bag",
      "household",
      "general",
    ],
  };

  // Score each waste type based on keyword matches
  const scores = {};
  for (const [type, keywords] of Object.entries(wasteTypeKeywords)) {
    scores[type] = keywords.reduce((score, keyword) => {
      return score + (resultsStr.includes(keyword) ? 1 : 0);
    }, 0);
  }

  // Find the type with highest score
  const maxScore = Math.max(...Object.values(scores));
  if (maxScore === 0) {
    // Default to household if no matches
    return "household";
  }

  const detectedType = Object.keys(scores).find(
    (type) => scores[type] === maxScore
  );

  return detectedType || "household";
}

/**
 * Estimate weight from image analysis
 * Uses visual cues like size, volume, and detected objects
 */
function estimateWeight(aiResults, wasteType) {
  // Base weights by waste type (in kg)
  const baseWeights = {
    household: 2.0,
    recyclable: 1.5,
    bulky: 15.0,
    organic: 1.0,
    hazardous: 0.5,
  };

  let estimatedWeight = baseWeights[wasteType] || 2.0;

  // Try to extract size information from AI results
  const resultsStr = JSON.stringify(aiResults).toLowerCase();

  // Adjust based on detected size indicators
  if (resultsStr.includes("large") || resultsStr.includes("big")) {
    estimatedWeight *= 1.5;
  } else if (resultsStr.includes("small") || resultsStr.includes("tiny")) {
    estimatedWeight *= 0.5;
  } else if (resultsStr.includes("medium")) {
    // Keep base weight
  }

  // Round to 1 decimal place
  return Math.round(estimatedWeight * 10) / 10;
}

/**
 * Determine weight category from estimated weight
 */
function getWeightCategory(estimatedWeight) {
  if (estimatedWeight < 1.0) {
    return "small";
  } else if (estimatedWeight < 5.0) {
    return "medium";
  } else {
    return "large";
  }
}

/**
 * Main function to analyze waste image
 * @param {string} imageUrl - URL of the image to analyze
 * @returns {Promise<Object>} Analysis result with waste_type, estimated_weight_kg, weight_category
 */
async function analyzeWasteImage(imageUrl) {
  try {
    console.log(`[AI] Starting analysis for image: ${imageUrl}`);

    // Step 1: Download image and convert to base64
    const { base64, mimeType } = await downloadImageAsBase64(imageUrl);
    console.log(`[AI] Image downloaded, size: ${base64.length} bytes`);

    // Step 2: Analyze image with AI
    let aiResults;
    try {
      // Try object detection first for better accuracy
      aiResults = await detectObjectsInImage(base64, mimeType);
    } catch (error) {
      console.warn("[AI] Object detection failed, using classification:", error.message);
      // Fallback to classification
      aiResults = await analyzeImageWithViT(base64, mimeType);
    }

    console.log(`[AI] Analysis complete, results:`, JSON.stringify(aiResults).substring(0, 200));

    // Step 3: Extract waste type from results
    const wasteType = extractWasteType(aiResults);
    console.log(`[AI] Detected waste type: ${wasteType}`);

    // Step 4: Estimate weight
    const estimatedWeightKg = estimateWeight(aiResults, wasteType);
    console.log(`[AI] Estimated weight: ${estimatedWeightKg} kg`);

    // Step 5: Determine weight category
    const weightCategory = getWeightCategory(estimatedWeightKg);

    const result = {
      waste_type: wasteType,
      estimated_weight_kg: estimatedWeightKg,
      weight_category: weightCategory,
      confidence: 0.8, // Default confidence, can be improved with better models
      ai_raw_results: aiResults, // Include raw results for debugging
    };

    console.log(`[AI] Final analysis result:`, result);
    return result;
  } catch (error) {
    console.error("[AI] Error in analyzeWasteImage:", error);
    throw error;
  }
}

module.exports = {
  analyzeWasteImage,
  extractWasteType,
  estimateWeight,
  getWeightCategory,
};
