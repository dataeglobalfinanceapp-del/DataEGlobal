require("dotenv").config();

const express = require("express");
const multer = require("multer");
const {
  TextractClient,
  AnalyzeExpenseCommand,
} = require("@aws-sdk/client-textract");

const app = express();
const port = process.env.PORT || 3000;
const textractClient = new TextractClient({
  region: process.env.AWS_REGION,
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter: (_req, file, callback) => {
    if (file.mimetype === "image/jpeg" || file.mimetype === "image/png") {
      callback(null, true);
      return;
    }

    const error = new Error("Unsupported file type");
    error.code = "UNSUPPORTED_FILE_TYPE";
    callback(error);
  },
}).single("image");

function findCardLast4(textValues) {
  const text = textValues.filter(Boolean).join(" ");
  const cardBrand =
    "(?:VISA|MC|MASTERCARD|MASTER\\s+CARD|AMEX|AMERICAN\\s+EXPRESS|DISCOVER)";
  const patterns = [
    /ending\s+in[\s:#-]*(\d{4})\b/i,
    /(?:\*{4}|X{4})[\s:-]*(\d{4})\b/i,
    new RegExp(`\\b${cardBrand}\\b[^\\d]{0,24}(\\d{4})\\b`, "i"),
    new RegExp(`\\b(\\d{4})\\b[^\\d]{0,24}\\b${cardBrand}\\b`, "i"),
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) {
      return match[1];
    }
  }

  return null;
}

function normalizeTransactionDate(value) {
  if (typeof value !== "string" || value.trim() === "") {
    return null;
  }

  const text = value.trim();
  const isoMatch = text.match(
    /^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:[T\s].*)?$/,
  );
  const receiptDateMatch = text.match(
    /^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2}|\d{4})$/,
  );

  let year;
  let month;
  let day;
  if (isoMatch) {
    year = Number(isoMatch[1]);
    month = Number(isoMatch[2]);
    day = Number(isoMatch[3]);
  } else if (receiptDateMatch) {
    month = Number(receiptDateMatch[1]);
    day = Number(receiptDateMatch[2]);
    year = Number(receiptDateMatch[3]);
    if (year < 100) year += 2000;
  } else {
    const parsedTimestamp = Date.parse(text);
    if (Number.isNaN(parsedTimestamp)) return null;
    const parsedDate = new Date(parsedTimestamp);
    year = parsedDate.getUTCFullYear();
    month = parsedDate.getUTCMonth() + 1;
    day = parsedDate.getUTCDate();
  }

  const validatedDate = new Date(Date.UTC(year, month - 1, day));
  if (
    validatedDate.getUTCFullYear() !== year ||
    validatedDate.getUTCMonth() + 1 !== month ||
    validatedDate.getUTCDate() !== day
  ) {
    return null;
  }

  return [year, month, day]
    .map((part, index) => String(part).padStart(index === 0 ? 4 : 2, "0"))
    .join("-");
}

function simplifyExpenseResponse(response) {
  const expenseDocument = response.ExpenseDocuments?.[0];
  const result = {
    vendorName: null,
    total: null,
    transactionDate: null,
    checkNumber: null,
    payee: null,
    cardLast4: null,
  };
  const cardTextValues = [];

  for (const field of expenseDocument?.SummaryFields || []) {
    const type = (field.Type?.Text || "")
      .trim()
      .toUpperCase()
      .replace(/[\s-]+/g, "_");
    const value = field.ValueDetection?.Text ?? null;
    const label = field.LabelDetection?.Text || "";

    if (type === "VENDOR_NAME") {
      result.vendorName = value;
    } else if (type === "INVOICE_RECEIPT_DATE") {
      result.transactionDate = normalizeTransactionDate(value);
    } else if (type === "TOTAL") {
      result.total = value;
    } else if (["CHECK_NUMBER", "CHECK_NO", "CHECK_NUM"].includes(type)) {
      result.checkNumber = value;
    } else if (["PAYEE", "RECEIVER_NAME"].includes(type)) {
      result.payee = value;
    }

    if (type === "OTHER") {
      if (/\bcheck\s*(?:number|no\.?|#)\b/i.test(label)) {
        result.checkNumber = value;
      } else if (/\bpayee\b|pay\s+to(?:\s+the\s+order\s+of)?/i.test(label)) {
        result.payee = value;
      }

      cardTextValues.push(label, value);
    }
  }

  const blocks = expenseDocument?.Blocks || response.Blocks || [];
  for (const block of blocks) {
    cardTextValues.push(block.Text);
  }

  result.cardLast4 = findCardLast4(cardTextValues);
  return result;
}

app.post("/textract/analyze", (req, res) => {
  upload(req, res, async (uploadError) => {
    if (uploadError) {
      if (
        uploadError instanceof multer.MulterError ||
        uploadError.code === "UNSUPPORTED_FILE_TYPE"
      ) {
        return res.status(400).json({ error: "Invalid image upload" });
      }

      console.error("Unexpected upload error:", uploadError);
      return res.status(400).json({ error: "Invalid image upload" });
    }

    if (!req.file) {
      return res.status(400).json({ error: "No image provided" });
    }

    try {
      const command = new AnalyzeExpenseCommand({
        Document: {
          Bytes: req.file.buffer,
        },
      });
      const response = await textractClient.send(command);
      const simplifiedExpense = simplifyExpenseResponse(response);
      console.log(
        "Textract simplified response:",
        JSON.stringify(simplifiedExpense, null, 2),
      );

      return res.json(simplifiedExpense);
    } catch (error) {
      console.error("Textract AnalyzeExpense error:", error);
      return res.status(500).json({ error: "Failed to analyze receipt" });
    }
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
