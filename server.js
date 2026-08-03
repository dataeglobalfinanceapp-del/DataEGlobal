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

function simplifyExpenseDocument(expenseDocument) {
  const result = {
    vendor: null,
    date: null,
    total: null,
    lineItems: [],
  };

  for (const field of expenseDocument?.SummaryFields || []) {
    const type = field.Type?.Text;
    const value = field.ValueDetection?.Text ?? null;

    if (type === "VENDOR_NAME") {
      result.vendor = value;
    } else if (type === "INVOICE_RECEIPT_DATE") {
      result.date = value;
    } else if (type === "TOTAL") {
      result.total = value;
    }
  }

  for (const group of expenseDocument?.LineItemGroups || []) {
    for (const lineItem of group.LineItems || []) {
      const parsedLineItem = {
        description: null,
        amount: null,
      };

      for (const field of lineItem.LineItemExpenseFields || []) {
        const type = field.Type?.Text;
        const value = field.ValueDetection?.Text ?? null;

        if (type === "ITEM") {
          parsedLineItem.description = value;
        } else if (type === "PRICE") {
          parsedLineItem.amount = value;
        }
      }

      result.lineItems.push(parsedLineItem);
    }
  }

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
      const expenseDocument = response.ExpenseDocuments?.[0];

      return res.json(simplifyExpenseDocument(expenseDocument));
    } catch (error) {
      console.error("Textract AnalyzeExpense error:", error);
      return res.status(500).json({ error: "Failed to analyze receipt" });
    }
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
