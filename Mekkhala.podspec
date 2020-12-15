Pod::Spec.new do |s|
    
    s.name = 'Mekkhala'
    s.version = '1.0.0'

    s.summary = 'Mekkhala 是一个自定义 Marquee Label 框架。'
    s.description = <<-DESC
                    Mekkhala 是一个自定义 Marquee Label 框架，可以高效的实现滚动 Label 的效果
                    DESC

    s.authors = { 'spirit-jsb' => 'sibo_jian_29903549@163.com' }
    s.license = 'MIT'
    
    s.homepage = 'https://github.com/spirit-jsb/Mekkhala.git'

    s.ios.deployment_target = '10.0'

    s.swift_versions = ['5.0']

    s.frameworks = 'Foundation'

    s.source = { :git => 'https://github.com/spirit-jsb/Mekkhala.git', :tag => s.version }

    s.default_subspecs = 'Core'
    
    s.subspec 'Core' do |sp|
        sp.source_files = ["Sources/Core/**/*.swift", "Sources/Mekkhala.h"]
    end

end