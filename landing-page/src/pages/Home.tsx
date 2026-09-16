import { useEffect } from "react";
import { Apps } from "@/components/Apps";
import { Couriers } from "@/components/Couriers";
import { Customers } from "@/components/Customers";
import { Ecosystem } from "@/components/Ecosystem";
import { FAQ } from "@/components/FAQ";
import { FinalCTA } from "@/components/FinalCTA";
import { Footer } from "@/components/Footer";
import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { HowItWorks } from "@/components/HowItWorks";
import { Local } from "@/components/Local";
import { Restaurants } from "@/components/Restaurants";
import { Technology } from "@/components/Technology";

export default function Home() {
  useEffect(() => {
    const nodes = document.querySelectorAll<HTMLElement>(".reveal");
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("in-view");
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.08 });
    nodes.forEach((node) => observer.observe(node));
    return () => observer.disconnect();
  }, []);

  return <div className="min-h-screen overflow-x-hidden bg-white text-[#111827]"><Header/><main><Hero/><div className="reveal"><HowItWorks/></div><div className="reveal"><Customers/></div><div className="reveal"><Restaurants/></div><div className="reveal"><Couriers/></div><div className="reveal"><Ecosystem/></div><div className="reveal"><Technology/></div><div className="reveal"><Local/></div><div className="reveal"><Apps/></div><div className="reveal"><FAQ/></div><FinalCTA/></main><Footer/></div>;
}
