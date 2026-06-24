//
//  ComponentsFormChrome.swift
//  PushLab
//
//  Created by Codex on 24/06/26.
//

import SwiftUI

struct ModuleScrollContainer<Content: View>: View {
    @ViewBuilder private let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct FormSectionCard<Content: View, Actions: View>: View {
    private let title: String
    private let description: String?
    private let systemImage: String?
    private let actions: Actions
    private let content: Content
    
    init(
        title: String,
        description: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.actions = actions()
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if let description {
                            Text(description)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer(minLength: 12)
                
                actions
            }
        }
    }
}

extension FormSectionCard where Actions == EmptyView {
    init(
        title: String,
        description: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            description: description,
            systemImage: systemImage,
            actions: { EmptyView() },
            content: content
        )
    }
}

struct AdaptiveFields<Wide: View, Compact: View>: View {
    private let wide: Wide
    private let compact: Compact
    
    init(
        @ViewBuilder wide: () -> Wide,
        @ViewBuilder compact: () -> Compact
    ) {
        self.wide = wide()
        self.compact = compact()
    }
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            wide
            compact
        }
    }
}

enum InlineMessageTone {
    case error
    case warning
    case success
    case info
    
    var color: Color {
        switch self {
        case .error:
            return .red
        case .warning:
            return .orange
        case .success:
            return .green
        case .info:
            return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "exclamationmark.octagon.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct InlineMessageCard: View {
    let text: String
    let tone: InlineMessageTone
    
    var body: some View {
        Label {
            Text(text)
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: tone.icon)
                .foregroundStyle(tone.color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            tone.color.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}

struct FieldHint: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
    }
}

private struct TextEditorSurfaceModifier: ViewModifier {
    let minHeight: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .frame(minHeight: minHeight)
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(
                Color(nsColor: .textBackgroundColor),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
            }
    }
}

extension View {
    func panelSurface(fill: Color) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    func tokenEditorSurface(minHeight: CGFloat = 72) -> some View {
        modifier(TextEditorSurfaceModifier(minHeight: minHeight))
    }
}
