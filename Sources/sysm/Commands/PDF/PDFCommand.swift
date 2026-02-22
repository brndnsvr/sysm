import ArgumentParser
import SysmCore

struct PDFCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf",
        abstract: "PDF processing and manipulation",
        subcommands: [
            PDFInfo_.self,
            PDFText.self,
            PDFSearch_.self,
            PDFPages.self,
            PDFThumbnail_.self,
            PDFMerge.self,
            PDFSplit.self,
            PDFRotate.self,
            PDFEncrypt.self,
            PDFDecrypt.self,
            PDFMetadata_.self,
            PDFAnnotations.self,
            PDFAnnotate.self,
            PDFWatermark.self,
            PDFCompress.self,
            PDFOCR.self,
            PDFImageToPDF.self,
            PDFOutline_.self,
            PDFPermissions_.self,
        ]
    )
}
