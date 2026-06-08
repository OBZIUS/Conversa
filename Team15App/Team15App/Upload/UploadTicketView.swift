import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Upload State

enum UploadState: Equatable {
    case idle
    case uploading(progress: Double, filename: String)
    case complete(filename: String)
}

// MARK: - Upload Ticket View

struct UploadTicketView: View {
    let onBack: () -> Void
    let onNext: (TicketData) -> Void

    @State private var uploadState: UploadState = .idle
    @State private var selectedImage: UIImage? = nil
    @State private var ticketData: TicketData = TicketData()

    // Photo picker
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // File importer (PDF)
    @State private var showFilePicker = false
    @State private var showCamera = false

    // Error
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppColors.ticketBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    BackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 26)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // MARK: - Title
                        Text("Upload Ticket")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppColors.navy)

                        Text("Upload a photo or document of your flight ticket or\nyour boarding pass")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.navy.opacity(0.6))
                            .lineSpacing(3)

                        Spacer().frame(height: 16)

                        // MARK: - Upload Box
                        if case .complete = uploadState {
                            VStack {
                                uploadBoxView
                                    .padding(24)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 340)
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                    .foregroundColor(Color(hex: "#E0E4F5"))
                            )
                        } else {
                            ScallopedCard {
                                uploadBoxView
                                    .padding(24)
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        // Photo picker sheet
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $selectedPhotoItem,
                      matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await startOCR(image: image, filename: "photo.jpg")
                }
            }
        }
        // File importer for PDF
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .jpeg, .png, UTType("public.image") ?? .image],
            allowsMultipleSelection: false
        ) { result in
            Task {
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let filename = url.lastPathComponent
                    _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }

                    if url.pathExtension.lowercased() == "pdf" {
                        await startOCRFromPDF(url: url, filename: filename)
                    } else if let data = try? Data(contentsOf: url),
                              let image = UIImage(data: data) {
                        await startOCR(image: image, filename: filename)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
        // Camera sheet
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                showCamera = false
                Task {
                    await startOCR(image: image, filename: "camera_photo.jpg")
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Upload Box

    @ViewBuilder
    private var uploadBoxView: some View {
        switch uploadState {
        case .idle:
            idleUploadBox

        case .uploading(let progress, _):
            uploadingBox(progress: progress)

        case .complete:
            completeBox
        }
    }

    // MARK: - Idle Box

    private var idleUploadBox: some View {
        VStack(spacing: 20) {
            // Dashed upload area
            Button(action: { showPhotoPicker = true }) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#EFF1F8"))
                            .frame(width: 48, height: 48)
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.navy)
                    }

                    Text("Tap to upload photo")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.navy)

                    Text("PNG, JPG, or PDF")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.navy.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundColor(AppColors.border)
                )
            }

            // OR divider
            HStack {
                Rectangle()
                    .fill(AppColors.border.opacity(0.5))
                    .frame(height: 1)
                Text("OR")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.navy.opacity(0.4))
                Rectangle()
                    .fill(AppColors.border.opacity(0.5))
                    .frame(height: 1)
            }
            .padding(.horizontal, 8)

            // Open Camera Button
            Button(action: { showCamera = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Open Camera")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.navy)
                .frame(width: 200, height: 44)
                .background(Color(hex: "#E8EBF8"))
                .cornerRadius(22)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Uploading Box

    private func uploadingBox(progress: Double) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text("\(Int(progress * 100))%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.navy)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#E8EBF8"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.navy)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.linear(duration: 0.2), value: progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)

            Text("Uploading Document...")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.navy)

            Spacer()
        }
        .frame(minHeight: 220)
    }

    // MARK: - Complete Box

    private var completeBox: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "#C2EBD5"))
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(Color(hex: "#2E7D32"))
                    .frame(width: 48, height: 48)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Upload Complete")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppColors.navy)

            // Clear upload button
            Button(action: { uploadState = .idle }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                    Text("Clear Upload")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(AppColors.navy)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(minHeight: 220)
    }

    // MARK: - Bottom Button

    @ViewBuilder
    private var bottomButton: some View {
        switch uploadState {
        case .idle, .uploading:
            Button("Upload") {}
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppColors.orange.opacity(0.6)))
                .disabled(true)

        case .complete:
            Button("Next") {
                onNext(ticketData)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: - OCR Helpers

    private func startOCR(image: UIImage, filename: String) async {
        let simFilename = filename
        // Animate progress
        await MainActor.run {
            uploadState = .uploading(progress: 0.0, filename: simFilename)
        }

        // Simulate progress steps while OCR runs in background
        let ocrTask = Task { await OCRService.recognizeText(from: image) }

        for step in stride(from: 0.1, through: 0.85, by: 0.1) {
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run {
                uploadState = .uploading(progress: step, filename: simFilename)
            }
        }

        let result = await ocrTask.value
        await MainActor.run {
            ticketData = result
            uploadState = .uploading(progress: 1.0, filename: simFilename)
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        await MainActor.run {
            uploadState = .complete(filename: simFilename)
        }
        
        // Auto-navigate to next screen after showing complete status briefly
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        await MainActor.run {
            if uploadState == .complete(filename: simFilename) {
                onNext(ticketData)
            }
        }
    }

    private func startOCRFromPDF(url: URL, filename: String) async {
        await MainActor.run {
            uploadState = .uploading(progress: 0.0, filename: filename)
        }

        let ocrTask = Task { await OCRService.recognizeText(fromPDF: url) }

        for step in stride(from: 0.1, through: 0.85, by: 0.1) {
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run {
                uploadState = .uploading(progress: step, filename: filename)
            }
        }

        let result = await ocrTask.value
        await MainActor.run {
            ticketData = result
            uploadState = .uploading(progress: 1.0, filename: filename)
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        await MainActor.run {
            uploadState = .complete(filename: filename)
        }
        
        // Auto-navigate to next screen after showing complete status briefly
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        await MainActor.run {
            if uploadState == .complete(filename: filename) {
                onNext(ticketData)
            }
        }
    }
}

// MARK: - Camera View (UIViewControllerRepresentable)

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    UploadTicketView(onBack: {}, onNext: { _ in })
}
