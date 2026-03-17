"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { 
  ArrowRight, 
  Shield, 
  Zap, 
  Users, 
  CreditCard, 
  BarChart3, 
  Smartphone, 
  Check, 
  Menu,
  X,
  TrendingUp,
  LayoutDashboard
} from "lucide-react";
import { cn } from "@/lib/utils";

// --- Components ---

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <nav 
      role="navigation"
      aria-label="Main Navigation"
      className={cn(
        "fixed top-0 left-0 right-0 z-50 transition-all duration-300 px-6 py-4",
        isScrolled ? "glass py-3" : "bg-transparent"
      )}
    >
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        <div className="flex items-center gap-2 group cursor-pointer">
          <div className="w-10 h-10 bg-rocket-gradient rounded-xl flex items-center justify-center shadow-lg shadow-brand-purple/40 group-hover:scale-110 transition-transform">
            <Smartphone className="text-white w-6 h-6" aria-hidden="true" />
          </div>
          <span className="text-xl font-bold tracking-tight text-gradient">FinanceApp</span>
        </div>

        {/* Desktop Menu */}
        <div className="hidden md:flex items-center gap-8">
          {[
            { name: "Features", href: "#features" },
            { name: "Premium", href: "#premium" },
            { name: "Security", href: "#security" }
          ].map((item) => (
            <a 
              key={item.name} 
              href={item.href}
              className="text-sm font-bold text-secondary hover:text-foreground transition-colors"
            >
              {item.name}
            </a>
          ))}
          <button 
            aria-label="Download FinanceApp"
            className="bg-foreground text-background px-6 py-2.5 rounded-full text-sm font-black hover:opacity-90 transition-all active:scale-95 shadow-xl"
          >
            Download App
          </button>
        </div>

        {/* Mobile Toggle */}
        <button 
          className="md:hidden text-foreground p-2"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          aria-expanded={mobileMenuOpen}
          aria-label="Toggle mobile menu"
        >
          {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="absolute top-full left-0 right-0 glass border-t border-white/10 p-6 flex flex-col gap-5 md:hidden"
          >
            {["Features", "Premium", "Security"].map((item) => (
              <a 
                key={item} 
                href={`#${item.toLowerCase()}`}
                className="text-lg font-black text-foreground hover:text-brand-purple transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                {item}
              </a>
            ))}
            <button className="bg-rocket-gradient text-white w-full py-4 rounded-xl font-black shadow-xl">
              Get Started for Free
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
};

const Hero = () => {
  return (
    <section className="relative pt-40 pb-20 overflow-hidden min-h-screen flex items-center">
      <div className="absolute top-[10%] right-[10%] w-[40%] h-[40%] bg-brand-purple/10 blur-[120px] rounded-full" />
      <div className="absolute bottom-[10%] left-[10%] w-[40%] h-[40%] bg-brand-pink/10 blur-[120px] rounded-full" />

      <div className="max-w-7xl mx-auto px-6 grid lg:grid-cols-2 gap-16 items-center relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full glass text-xs font-black text-brand-orange mb-8 uppercase tracking-widest shadow-sm">
            <span className="flex h-2 w-2 rounded-full bg-brand-orange animate-pulse" />
            V 2.0 is now live
          </div>
          <h1 className="text-5xl md:text-7xl lg:text-8xl font-black leading-[1.1] mb-8 tracking-tighter text-foreground">
            Financial <br />
            <span className="text-gradient hover:brightness-110 transition-all">freedom</span> <br />
            reimagined.
          </h1>
          <p className="text-xl md:text-2xl text-secondary mb-10 max-w-lg leading-relaxed font-bold">
            The most beautiful and powerful way to master your money. Sync, track, and save with bank-grade security.
          </p>
          <div className="flex flex-col sm:flex-row gap-5">
            <button 
              aria-label="Sign up for FinanceApp"
              className="bg-rocket-gradient px-10 py-5 rounded-2xl font-black text-white shadow-2xl shadow-brand-purple/30 hover:scale-[1.03] active:scale-95 transition-all flex items-center justify-center gap-3 group"
            >
              Start Your Journey <ArrowRight className="w-6 h-6 group-hover:translate-x-1.5 transition-transform" />
            </button>
            <button className="px-10 py-5 rounded-2xl font-black text-foreground glass border-2 border-foreground/10 hover:bg-foreground/5 transition-all active:scale-95">
              Watch Demo
            </button>
          </div>
          
          <div className="mt-16 flex items-center gap-5">
            <div className="flex -space-x-3">
              {[1, 2, 3, 4].map((i) => (
                <div 
                  key={i} 
                  className={cn(
                    "w-12 h-12 rounded-full border-4 border-background flex items-center justify-center font-bold overflow-hidden",
                    i === 1 && "bg-brand-purple",
                    i === 2 && "bg-brand-pink",
                    i === 3 && "bg-brand-orange",
                    i === 4 && "bg-blue-600"
                  )}
                >
                  <Users className="text-white w-5 h-5 opacity-40" />
                </div>
              ))}
            </div>
            <div className="flex flex-col text-left">
              <span className="text-foreground font-black leading-tight">10k+ active users</span>
              <span className="text-secondary text-sm font-bold leading-tight">Managing over $150M in assets</span>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1, delay: 0.2 }}
          className="relative lg:ml-12"
        >
          {/* Mockup Card - Clean & Integrated */}
          <div className="relative z-10 p-1 rounded-[3.5rem] bg-gradient-to-br from-white/20 to-transparent shadow-[0_0_100px_rgba(64,26,128,0.15)] animate-float">
             <div className="bg-zinc-950 rounded-[3.25rem] overflow-hidden aspect-[9/18.5] max-w-[340px] mx-auto border-4 border-white/5 relative shadow-inner">
                {/* App Screen Mock content */}
                <div className="p-8 pt-16">
                  <div className="h-8 w-28 bg-rocket-gradient rounded-full mb-12" />
                  <div className="space-y-8">
                    <div className="h-44 w-full glass rounded-[2.5rem] flex flex-col items-center justify-center gap-4 overflow-hidden p-8">
                      <div className="flex items-end gap-2">
                        <div className="w-5 h-14 bg-white/5 rounded-t-xl" />
                        <div className="w-5 h-24 bg-brand-purple/40 rounded-t-xl" />
                        <div className="w-5 h-32 bg-rocket-gradient rounded-t-xl" />
                        <div className="w-5 h-20 bg-white/5 rounded-t-xl" />
                      </div>
                      <span className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] leading-none">Net Worth Trend</span>
                    </div>
                    {[1, 2].map(i => (
                      <div key={i} className="h-16 w-full glass rounded-2xl flex items-center justify-between px-6">
                        <div className="flex gap-4 items-center">
                          <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center", i === 1 ? "bg-green-500/10 text-green-500" : "bg-brand-pink/10 text-brand-pink")}>
                            {i === 1 ? <TrendingUp size={20} /> : <LayoutDashboard size={20} />}
                          </div>
                          <div className="h-2.5 w-20 bg-white/10 rounded-full" />
                        </div>
                        <div className="h-2.5 w-12 bg-white/10 rounded-full" />
                      </div>
                    ))}
                  </div>
                </div>
                {/* iPhone style notch */}
                <div className="absolute top-2 left-1/2 -translate-x-1/2 h-8 w-40 bg-black rounded-b-3xl border-x border-b border-white/5" />
             </div>
          </div>
          
          {/* Branded Floating Elements - High Contrast */}
          <motion.div 
            animate={{ y: [0, -15, 0] }}
            transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
            className="absolute -top-12 -right-8 glass p-6 rounded-3xl shadow-2xl z-20 border-2 border-brand-orange/40 backdrop-blur-3xl"
          >
            <div className="flex items-center gap-5">
              <div className="w-12 h-12 bg-brand-orange/10 rounded-2xl flex items-center justify-center text-brand-orange shadow-inner">
                <TrendingUp className="w-7 h-7" strokeWidth={3} />
              </div>
              <div className="text-left">
                <p className="text-[10px] text-brand-orange font-black uppercase tracking-[0.25em] mb-1">Growth</p>
                <p className="font-black text-2xl text-foreground">+14.2%</p>
              </div>
            </div>
          </motion.div>

          <motion.div 
            animate={{ y: [0, 10, 0] }}
            transition={{ duration: 6, repeat: Infinity, ease: "easeInOut", delay: 1 }}
            className="absolute -bottom-8 -left-16 glass p-6 rounded-3xl shadow-2xl z-20 border-2 border-brand-purple/40 backdrop-blur-3xl"
          >
            <div className="flex items-center gap-5">
              <div className="w-12 h-12 bg-brand-purple/10 rounded-2xl flex items-center justify-center text-brand-purple">
                <Shield className="w-7 h-7" strokeWidth={3} />
              </div>
              <div className="text-left">
                <p className="text-[10px] text-brand-purple font-black uppercase tracking-[0.25em] mb-1">Secure</p>
                <p className="font-black text-xl text-foreground leading-tight tracking-tight">AES-256 <br />Verified</p>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
};

const Features = () => {
  const features = [
    {
      title: "Secure Sync",
      desc: "Connect over 10,000 financial institutions globally via Plaid with military-grade encryption.",
      icon: <Zap className="w-8 h-8" />,
      color: "from-blue-600 to-cyan-500",
      glow: "shadow-blue-500/30"
    },
    {
      title: "Smart Budgeting",
      desc: "AI-powered insights that help you set realistic goals and track spending in real-time.",
      icon: <BarChart3 className="w-8 h-8" />,
      color: "from-brand-purple to-brand-pink",
      glow: "shadow-brand-purple/30"
    },
    {
      title: "Team Wealth",
      desc: "The only app designed for financial transparency with your partner or family.",
      icon: <Users className="w-8 h-8" />,
      color: "from-orange-600 to-yellow-500",
      glow: "shadow-brand-orange/30"
    },
    {
      title: "Auto-Discovery",
      desc: "Stop leaking money. We automatically detect and help you manage unused subscriptions.",
      icon: <CreditCard className="w-8 h-8" />,
      color: "from-emerald-600 to-teal-500",
      glow: "shadow-emerald-500/30"
    }
  ];

  return (
    <section id="features" className="py-32 relative overflow-hidden bg-background">
      <div className="max-w-7xl mx-auto px-6">
        <div className="flex flex-col items-center text-center mb-28">
          <div className="px-6 py-2 rounded-full bg-brand-purple/5 text-brand-purple text-[10px] font-black uppercase tracking-[0.3em] mb-8 border border-brand-purple/20">
            Advanced Capabilities
          </div>
          <h2 className="text-4xl md:text-6xl font-black mb-8 tracking-tight text-foreground">Master your money.</h2>
          <p className="text-secondary text-xl max-w-2xl font-bold leading-relaxed">
            Stop guessing and start knowing. Everything you need to reach your financial goals in one intuitive workspace.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((f, i) => (
            <motion.div
              key={i}
              whileHover={{ y: -10, scale: 1.02 }}
              className="glass p-12 rounded-[3.5rem] group hover:border-brand-purple/30 transition-all duration-500 flex flex-col items-start shadow-xl shadow-black/5"
            >
              <div className={cn("w-20 h-20 rounded-[1.75rem] flex items-center justify-center mb-10 bg-gradient-to-br shadow-2xl", f.color, f.glow)}>
                {React.cloneElement(f.icon as React.ReactElement<{ className?: string }>, { className: "text-white" })}
              </div>
              <h3 className="text-2xl font-black mb-5 tracking-tight group-hover:text-brand-purple transition-all text-foreground">{f.title}</h3>
              <p className="text-secondary text-base leading-relaxed font-bold">{f.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

const Premium = () => {
  return (
    <section id="premium" className="py-40 relative overflow-hidden bg-background">
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-[600px] bg-brand-purple/5 blur-[120px] rounded-full pointer-events-none" />
      
      <div className="max-w-6xl mx-auto px-6">
        <div className="glass p-12 md:p-24 rounded-[4.5rem] relative overflow-hidden shadow-2xl border-2 border-foreground/5">
          <div className="absolute top-0 right-0 p-12 md:p-16">
             <div className="px-8 py-3 bg-brand-orange text-white text-[10px] font-black uppercase tracking-[0.5em] rounded-full shadow-2xl shadow-brand-orange/40 rotate-6 flex items-center gap-3">
               <Zap size={14} fill="currentColor" /> Limitless
             </div>
          </div>
          
          <div className="grid lg:grid-cols-2 gap-24 items-center">
            <div className="text-left relative z-10">
              <div className="text-brand-pink font-black text-[10px] uppercase tracking-[0.4em] mb-6">Pricing Plans</div>
              <h2 className="text-5xl md:text-8xl font-black mb-10 leading-none tracking-tighter text-foreground">
                FinanceApp <br />
                <span className="text-gradient">Premium</span>
              </h2>
              <p className="text-secondary text-xl font-bold mb-14 leading-relaxed max-w-sm">Experience the absolute peak of personal financial management.</p>
              
              <ul className="grid gap-7 mb-16">
                {[
                  "Unlimited Bank Accounts",
                  "Advanced Data Visualizations",
                  "Priority Export & Concierge Support",
                  "Collaborative Dashboards & Sharing",
                  "Custom Automated Category Rules"
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-5 text-lg font-black text-foreground">
                    <div className="w-8 h-8 rounded-full bg-brand-orange/10 flex items-center justify-center text-brand-orange border-2 border-brand-orange/20 shadow-inner">
                      <Check className="w-5 h-5" strokeWidth={4} />
                    </div>
                    {item}
                  </li>
                ))}
              </ul>

              <button className="w-full bg-rocket-gradient py-7 rounded-[2.5rem] font-black text-xl text-white shadow-2xl shadow-brand-purple/40 hover:scale-[1.02] active:scale-95 transition-all outline outline-4 outline-brand-purple/10">
                Unlock Everything for $4.99 / mo
              </button>
              <p className="text-center text-secondary text-xs font-black mt-6 tracking-widest uppercase opacity-40">No commitment. Cancel anytime.</p>
            </div>

            <div className="hidden lg:block">
               <div className="aspect-square glass rounded-full flex items-center justify-center relative p-16 shadow-2xl border-4 border-foreground/5">
                  <div className="absolute inset-6 rounded-full border-4 border-dashed border-foreground/10 animate-[spin_40s_linear_infinite] opacity-30" />
                  <div className="absolute inset-16 rounded-full border-2 border-foreground/5 animate-[spin_25s_linear_infinite_reverse] opacity-20" />
                  <Smartphone className="w-40 h-40 text-foreground opacity-10" />
                  <motion.div 
                    animate={{ scale: [1, 1.3, 1], opacity: [0.2, 0.5, 0.2] }} 
                    transition={{ duration: 4, repeat: Infinity }}
                    className="absolute w-32 h-32 bg-brand-pink/20 blur-[100px] rounded-full" 
                  />
                  <div className="absolute top-1/4 right-1/4 w-16 h-16 bg-rocket-gradient rounded-[1.75rem] flex items-center justify-center shadow-2xl animate-bounce border-4 border-white/20">
                    <Check className="text-white w-8 h-8" strokeWidth={4} />
                  </div>
               </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

const Security = () => {
  return (
    <section id="security" className="py-40 bg-background relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 flex flex-col items-center text-center relative z-10">
        <div className="w-28 h-28 glass rounded-[2.5rem] flex items-center justify-center mb-12 text-brand-orange border-2 border-brand-orange/30 shadow-2xl shadow-brand-orange/10">
          <Shield className="w-14 h-14" strokeWidth={2.5} />
        </div>
        <h2 className="text-5xl md:text-8xl font-black mb-10 leading-[0.9] tracking-tighter text-foreground">
          Trust is our <br />
          <span className="text-gradient">currency.</span>
        </h2>
        <p className="text-secondary text-xl md:text-2xl font-bold max-w-3xl mb-20 leading-relaxed">
          We use bank-grade 256-bit AES encryption to protect your data. Your credentials never touch our servers, and we never sell your data to anyone. **Period.**
        </p>
        
        <div className="flex flex-wrap justify-center items-center gap-16 md:gap-24 opacity-30 hover:opacity-100 transition-opacity duration-700 grayscale hover:grayscale-0 group pb-12">
           {/* Symbolic Partner Logos - Cleaner */}
           <div className="flex flex-col items-center gap-4">
              <div className="h-10 w-32 bg-foreground/10 rounded-2xl group-hover:bg-cyan-500/20 transition-all border border-foreground/5 flex items-center justify-center font-black text-[10px] tracking-widest text-foreground/40">PLAID SYNC</div>
           </div>
           <div className="flex flex-col items-center gap-4">
              <div className="h-10 w-32 bg-foreground/10 rounded-2xl group-hover:bg-blue-600/20 transition-all border border-foreground/5 flex items-center justify-center font-black text-[10px] tracking-widest text-foreground/40">AES-256</div>
           </div>
           <div className="flex flex-col items-center gap-4">
              <div className="h-10 w-32 bg-foreground/10 rounded-2xl group-hover:bg-brand-purple/20 transition-all border border-foreground/5 flex items-center justify-center font-black text-[10px] tracking-widest text-foreground/40">GDPR READY</div>
           </div>
        </div>
      </div>

      {/* Branded decorative elements instead of muddy grid */}
      <div className="absolute top-1/2 left-0 -translate-y-1/2 w-[300px] h-[300px] bg-brand-orange/5 blur-[100px] rounded-full" />
      <div className="absolute top-1/2 right-0 -translate-y-1/2 w-[300px] h-[300px] bg-brand-purple/5 blur-[100px] rounded-full" />
    </section>
  );
};

const Footer = () => {
  return (
    <footer className="py-40 border-t border-foreground/5 bg-background relative z-10">
      <div className="max-w-7xl mx-auto px-6 grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-20">
        <div className="col-span-2 text-left">
           <div className="flex items-center gap-4 mb-10">
            <div className="w-12 h-12 bg-rocket-gradient rounded-[1.25rem] flex items-center justify-center shadow-xl shadow-brand-purple/30">
              <Smartphone className="text-white w-7 h-7" />
            </div>
            <span className="text-3xl font-black tracking-tighter text-gradient">FinanceApp</span>
          </div>
          <p className="text-secondary text-xl font-bold max-w-sm leading-relaxed mb-10">
            The ultimate tool for personal financial freedom. Beautifully designed, powerfully built for the next generation.
          </p>
          <div className="flex gap-5">
             {[1,2,3].map(i => (
               <div key={i} className="w-12 h-12 rounded-2xl glass flex items-center justify-center text-secondary hover:text-foreground hover:border-brand-purple hover:scale-110 transition-all cursor-pointer">
                 <div className="w-5 h-5 bg-current rounded-md" />
               </div>
             ))}
          </div>
        </div>

        {["Product", "Company", "Legal"].map((cat) => (
          <div key={cat} className="text-left">
            <h4 className="font-black mb-12 text-[10px] uppercase tracking-[0.4em] text-brand-orange">{cat}</h4>
            <ul className="space-y-8">
              {["Features", "Premium", "Security", "Support"].map((item) => (
                <li key={item}>
                  <a href="#" className="text-lg font-black text-secondary hover:text-foreground transition-all">
                    {item}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="max-w-7xl mx-auto px-6 mt-40 pt-16 border-t border-foreground/5 flex flex-col md:flex-row items-center justify-between gap-8 text-sm font-black text-secondary/40 tracking-widest uppercase">
        <p>&copy; 2026 FinanceApp Inc. Master your destiny.</p>
        <div className="flex gap-12">
          <a href="#" className="hover:text-foreground transition-colors">Privacy</a>
          <a href="#" className="hover:text-foreground transition-colors">Terms</a>
          <a href="#" className="hover:text-foreground transition-colors">Security</a>
        </div>
      </div>
    </footer>
  );
};

export default function Home() {
  return (
    <main className="bg-background selection:bg-brand-purple selection:text-white antialiased">
      <Navbar />
      <Hero />
      <Features />
      <Premium />
      <Security />
      <Footer />
      
      {/* Global decorative background - Cleaner & Subtle */}
      <div className="fixed inset-0 -z-50 opacity-[0.1] pointer-events-none overflow-hidden">
        <div className="absolute top-[10%] right-[-10%] w-[1200px] h-[1200px] bg-brand-purple/40 blur-[250px] rounded-full animate-pulse-slow" />
        <div className="absolute bottom-[-10%] left-[-10%] w-[1200px] h-[1200px] bg-brand-pink/30 blur-[250px] rounded-full animate-pulse-slow" />
      </div>
    </main>
  );
}
